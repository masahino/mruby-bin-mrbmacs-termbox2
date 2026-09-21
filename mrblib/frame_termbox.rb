# Mrbmacs
module Mrbmacs
  # Frame class for termbox
  class Frame
    TERMBOX_KEYMAP = {
      Termbox2::KEY_CTRL_A => 'C-a',
      Termbox2::KEY_CTRL_B => 'C-b',
      Termbox2::KEY_CTRL_C => 'C-c',
      Termbox2::KEY_CTRL_D => 'C-d',
      Termbox2::KEY_CTRL_E => 'C-e',
      Termbox2::KEY_CTRL_F => 'C-f',
      Termbox2::KEY_CTRL_G => 'C-g',
      # Termbox2::KEY_CTRL_H => 'C-h',
      Termbox2::KEY_CTRL_I => 'C-i',
      Termbox2::KEY_CTRL_J => 'C-j',
      Termbox2::KEY_CTRL_K => 'C-k',
      Termbox2::KEY_CTRL_L => 'C-l',
      Termbox2::KEY_CTRL_M => 'C-m',
      Termbox2::KEY_CTRL_N => 'C-n',
      Termbox2::KEY_CTRL_O => 'C-o',
      Termbox2::KEY_CTRL_P => 'C-p',
      Termbox2::KEY_CTRL_Q => 'C-q',
      Termbox2::KEY_CTRL_R => 'C-r',
      Termbox2::KEY_CTRL_S => 'C-s',
      Termbox2::KEY_CTRL_T => 'C-t',
      Termbox2::KEY_CTRL_U => 'C-u',
      Termbox2::KEY_CTRL_V => 'C-v',
      Termbox2::KEY_CTRL_W => 'C-w',
      Termbox2::KEY_CTRL_X => 'C-x',
      Termbox2::KEY_CTRL_Y => 'C-y',
      Termbox2::KEY_CTRL_Z => 'C-z',
      Termbox2::KEY_SPACE => ' ',
      Termbox2::KEY_TAB => 'Tab',
      Termbox2::KEY_ENTER => 'Enter',
      Termbox2::KEY_ESC => 'Escape',
      Termbox2::KEY_CTRL_BACKSLASH => 'C-\\',
      Termbox2::KEY_CTRL_SLASH => 'C-/',
      Termbox2::KEY_CTRL_UNDERSCORE => 'C-_',
      Termbox2::KEY_F1 => 'F1',
      Termbox2::KEY_F2 => 'F2',
      Termbox2::KEY_F3 => 'F3',
      Termbox2::KEY_F4 => 'F4',
      Termbox2::KEY_F5 => 'F5',
      Termbox2::KEY_F6 => 'F6',
      Termbox2::KEY_F7 => 'F7',
      Termbox2::KEY_F8 => 'F8',
      Termbox2::KEY_F9 => 'F9',
      Termbox2::KEY_F10 => 'F10',
      Termbox2::KEY_F11 => 'F11',
      Termbox2::KEY_F12 => 'F12'
    }.freeze

    TERMBOX_KEYSYMS = {
      Termbox2::KEY_INSERT => Scintilla::SCK_INSERT,
      Termbox2::KEY_DELETE => Scintilla::SCK_DELETE,
      Termbox2::KEY_HOME => Scintilla::SCK_HOME,
      Termbox2::KEY_END => Scintilla::SCK_END,
      Termbox2::KEY_ARROW_UP => Scintilla::SCK_UP,
      Termbox2::KEY_ARROW_DOWN => Scintilla::SCK_DOWN,
      Termbox2::KEY_ARROW_LEFT => Scintilla::SCK_LEFT,
      Termbox2::KEY_ARROW_RIGHT => Scintilla::SCK_RIGHT,
      Termbox2::KEY_BACKSPACE => Scintilla::SCK_BACK,
      Termbox2::KEY_TAB => Scintilla::SCK_TAB,
      Termbox2::KEY_ENTER => Scintilla::SCK_RETURN,
      Termbox2::KEY_SPACE => 32,
      Termbox2::KEY_BACKSPACE2 => Scintilla::SCK_BACK,
      Termbox2::KEY_MOUSE_LEFT => 1,
      Termbox2::KEY_MOUSE_MIDDLE => 2,
      Termbox2::KEY_MOUSE_RIGHT => 3,
      Termbox2::KEY_MOUSE_WHEEL_UP => 4,
      Termbox2::KEY_MOUSE_WHEEL_DOWN => 5
    }.freeze

    def initialize(buffer)
      Termbox2.init
      Termbox2.set_output_mode(Termbox2::OUTPUT_TRUECOLOR)
      Termbox2.set_input_mode(Termbox2::INPUT_ESC | Termbox2::INPUT_MOUSE)
      Termbox2.hide_cursor
      @width = Termbox2.width
      @height = Termbox2.height
      @sci_notifications = []
      @edit_win = EditWindowTermbox.new(self, buffer, 0, 0, Termbox2.width, Termbox2.height - 1)
      @view_win = @edit_win.sci
      @echo_win = new_echowin
      @edit_win_list = [@edit_win]
      @view_win.refresh
    end

    def new_editwin(buffer, left, top, width, height)
      EditWindowTermbox.new(self, buffer, left, top, width, height)
    end

    def send_mouse(event, win)
      tmp_win = get_edit_win_from_pos(event.y, event.x)
      return if tmp_win.nil?

      if tmp_win.sci != win && win != @echo_win
        switch_window(tmp_win)
        win = tmp_win.sci
      end
      mouse_event = determine_mouse_event(event)
      c = TERMBOX_KEYSYMS.fetch(event.key, 0)
      win.send_mouse(mouse_event, c, event.y, event.x, false, false, false)
    end

    def determine_mouse_event(event)
      return Scintilla::SCM_DRAG if event.mod == Termbox2::MOD_MOTION
      return Scintilla::SCM_RELEASE if event.key == Termbox2::KEY_MOUSE_RELEASE

      Scintilla::SCM_PRESS
    end

    def send_key(event, win = nil)
      win = @view_win if win.nil?
      case event.type
      when Termbox2::EVENT_KEY
        ctrl = false
        c = event.ch
        if strfkey(event)[0..1] == 'C-'
          ctrl = true
          c = strfkey(event)[2].ord
        end
        c = TERMBOX_KEYSYMS[event.key] if TERMBOX_KEYSYMS.key? event.key
        win.send_key(c, false, ctrl, false) if c != 0
      when Termbox2::EVENT_MOUSE
        send_mouse(event, win)
      end
    end

    def waitkey(_win = nil)
      [nil, Termbox2.poll_event]
    end

    def strfkey(event)
      return TERMBOX_KEYMAP[event.key] if TERMBOX_KEYMAP.key?(event.key)

      key_str = if event.mod == Termbox2::MOD_ALT
                  'M-'
                else
                  ''
                end
      if event.key == 0 && event.ch == 0
        key_str += 'C- '
      else
        key_str += Termbox2.utf8_unicode_to_char(event.ch)
      end
      key_str
    end

    def modeline(app, win = @edit_win)
      mode_str = get_mode_str(app)
      if mode_str.length < win.width - 1
        mode_str += '-' * (win.width - mode_str.length)
      else
        mode_str = mode_str[0, win.width - 1]
      end
      win.mode_win.update(mode_str)
      win.refresh_modeline
    end

    def modeline_refresh(_app)
      @edit_win_list.map(&:refresh_modeline)
    end

    def exit
      Termbox2.shutdown
    end

    def delete_other_window
      @edit_win_list.each do |w|
        if w != @edit_win
          w.sci.sci_add_refdocument(w.buffer.docpointer)
          w.delete
        end
      end
      @edit_win_list.delete_if { |w| w != @edit_win }
      @edit_win.x1 = 0
      @edit_win.x2 = Termbox2.width - 1
      @edit_win.y1 = 0
      @edit_win.y2 = Termbox2.height - 1 - 1
      @edit_win.compute_area
      @edit_win.refresh
    end

    def extend_width(new_width)
      @edit_win_list.each do |win|
        if win.x2 == @width - 1
          win.x2 = new_width - 1
          win.compute_area
        end
      end
    end

    def extend_height(new_height)
      @edit_win_list.each do |win|
        if win.y2 == @height - 1 - 1
          win.y2 = new_height - 1 - 1
          win.compute_area
        end
      end
    end

    def shorten_width(new_width)
      @edit_win_list.each do |win|
        if win.x1 < new_width - 1 && new_width - 1 < win.x2
          win.x2 = new_width - 1
          win.compute_area
        end
      end
    end

    def shorten_height(new_height)
      @edit_win_list.each do |win|
        if win.y1 < new_height - 1 - 1 && new_height - 1 - 1 < win.y2
          win.y2 = new_height - 1 - 1
          win.compute_area
        end
      end
    end

    def delete_too_small_window(new_width, new_height)
      @edit_win_list.each do |win|
        delete_window(win) if new_width - 1 < win.x1
        delete_window(win) if new_height - 1 - 1 < win.y1
      end
    end

    def resize_terminal(new_width, new_height)
      if @edit_win_list.size == 1
        @edit_win.x2 = new_width - 1
        @edit_win.y2 = new_height - 1 - 1
        @edit_win.compute_area
        @edit_win.refresh
      else
        delete_too_small_window(new_width, new_height) if new_width < @width || new_height < @height
        if new_width > @width
          extend_width(new_width)
        elsif new_width < @width
          shorten_width(new_width)
        end
        if new_height > @height
          extend_height(new_height)
        elsif new_height < @height
          shorten_height(new_height)
        end
      end
      @width = new_width
      @height = new_height
      refresh_all
    end
  end
end
