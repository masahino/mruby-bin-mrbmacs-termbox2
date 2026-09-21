module Mrbmacs
  # Application class for Termbox2
  class ApplicationTermbox < ApplicationTerminal
    def add_buffer_to_frame(buffer) end

    def doscan(prefix = '')
      loop do
        ev = if prefix == ''
               Termbox2.peek_event(1)
             else
               Termbox2.poll_event
             end
        return if ev.nil?

        if ev.type == Termbox2::EVENT_RESIZE
          @frame.resize_terminal(ev.w, ev.h)
          @current_buffer = @frame.edit_win.buffer
          return
        end

        key_str = @frame.strfkey(ev)
        add_recent_key(key_str)
        key_str = prefix + key_str
        # key_str.sub!(/^Escape /, 'M-')
        key_str = 'M-' + key_str[7..].to_s if key_str.start_with?('Escape ')
        command = key_scan(key_str)
        if command.nil?
          @frame.send_key(ev)
          @current_buffer = @frame.edit_win.buffer if @current_buffer.name != @frame.edit_win.buffer.name
        elsif command.is_a?(Integer)
          @frame.view_win.send_message(command, nil, nil)
        elsif command == 'prefix'
          doscan("#{key_str} ")
        else
          extend(command)
        end
        prefix = ''
      end
    end

    def editloop
      add_io_read_event($stdin) { doscan }
      @frame.view_win.refresh
      loop do
        # notification event
        while @frame.sci_notifications.length > 0
          e = @frame.sci_notifications.shift
          # @logger.debug "sci notification [#{e['code']}]"
          call_sci_event(e)
        end
        @frame.view_win.refresh
        # set cursor pos for IME
        # current_pos = @frame.view_win.sci_get_current_pos
        # x = @frame.view_win.sci_point_x_from_position(0, current_pos)
        # y = @frame.view_win.sci_point_y_from_position(0, current_pos)
        # @frame.view_win.setpos(y, x)

        # IO event
        readable, _writable = IO.select(@readings)
        readable.each do |ri|
          next if @io_handler[ri].nil?

          begin
            @io_handler[ri].call(self, ri)
          rescue => e
            @logger.error e.to_s
            @logger.error e.backtrace
            @frame.echo_puts(e.to_s)
          end
        end

        @frame.view_win.refresh
        @frame.modeline(self)
      end
    end
  end
end
