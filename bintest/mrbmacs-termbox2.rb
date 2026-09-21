require 'open3'
require 'fileutils'
require 'timeout'
require 'pty'
require 'io/console'

FRONTEND_GEM_NAME = 'mruby-bin-mrbmacs-termbox2'

$script_dir = "#{File.dirname(__FILE__)}/scripts/"
$capture_file = "#{File.dirname(__FILE__)}/.capture"

# mrbmacs-termbox2 opens /dev/tty and reads the terminal size during startup
# (tb_init), so it needs a real, sized terminal. A plain pipe (Open3) makes
# tb_init fail; an unsized CI PTY makes it come up 0x0. Run it under a PTY with
# an explicit winsize instead.
def termbox_run(args, timeout: 30)
  output = +''
  status = nil
  PTY.spawn("#{cmd('mrbmacs-termbox2')} #{args}") do |r, w, pid|
    w.winsize = [40, 120] rescue nil
    begin
      Timeout.timeout(timeout) { loop { output << r.readpartial(4096) } }
    rescue Errno::EIO, EOFError
      # child exited and closed the pty - expected
    rescue Timeout::Error
      Process.kill('KILL', pid) rescue nil
    end
    _pid, status = Process.wait2(pid) rescue [nil, nil]
  end
  [output, status]
end

# Assert the run exited cleanly; on failure show the signal/status and the
# tail of the merged PTY output so CI logs are actionable.
def assert_run_ok(status, output)
  ok = status.is_a?(Process::Status) && status.exitstatus == 0
  assert_true ok,
              "mrbmacs-termbox2 did not exit cleanly: #{status.inspect}\n" \
              "--- last output ---\n#{output.to_s[-1000..] || output}"
end

# Run a -l script that reports lines through ENV['MRBMACS_BINTEST_OUT'].
# The PTY merges stdout/stderr with termbox2's escape output, so scripts write
# their assertions to a file instead.
def termbox_capture(script)
  File.delete($capture_file) if File.exist?($capture_file)
  ENV['MRBMACS_BINTEST_OUT'] = $capture_file
  output, status = termbox_run("-q -l #{$script_dir}#{script}")
  assert_run_ok(status, output)
  File.exist?($capture_file) ? File.read($capture_file).split("\n") : []
end

# Copy +input_file+ aside, let +test_name+ edit and save it, then compare the
# saved bytes with the recorded expectation.
def run_edit_test(test_name, input_file = 'test.input')
  edit_file = "#{File.dirname(__FILE__)}/#{test_name}.input"
  output_file = "#{$script_dir}#{test_name}.output"
  FileUtils.cp "#{File.dirname(__FILE__)}/#{input_file}", edit_file
  output, status = termbox_run("-q -l #{$script_dir}#{test_name} #{edit_file}")
  assert_run_ok(status, output)
  assert_equal File.read(output_file), File.read(edit_file)
  File.delete edit_file
end

assert('report the generated frontend version') do
  version_file = File.join(
    ENV.fetch('BUILD_DIR'), 'mrbgems', FRONTEND_GEM_NAME, 'version.txt'
  )
  expected_version = File.read(version_file).strip
  stdout, stderr, status = Open3.capture3(
    "#{cmd('mrbmacs-termbox2')} --version"
  )

  assert_equal 0, status.to_i
  assert_equal '', stderr
  assert_equal expected_version, stdout.strip
end

assert('every non-interactive command runs against the real Scintilla') do
  lines = termbox_capture('all-commands')

  failures = lines.select { |line| line.start_with?('NG ') }
  assert_equal [], failures
  # A base command in neither the allow nor the skip list needs a decision.
  undecided = lines.select { |line| line.start_with?('UNLISTED ') }
  assert_equal [], undecided
  # Without the trailing marker the script stopped early; the last line names
  # the command it was running.
  assert_true lines.include?('done'),
              "all-commands stopped at: #{lines.last.inspect}"
end

assert('edit-japanese') do
  run_edit_test('edit-japanese')
end

assert('rectangle') do
  run_edit_test('rectangle')
end

assert('comment') do
  run_edit_test('comment', 'test2.input')
end

assert('eol-crlf') do
  run_edit_test('eol-crlf', 'test-utf8-dos.input')
end

assert('encoding-cp932') do
  run_edit_test('encoding-cp932')
end

assert('window') do
  # The script reports any ERROR line logged while splitting and closing.
  assert_equal [], termbox_capture('window')
end
