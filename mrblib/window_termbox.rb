module Mrbmacs
  # EditWindow
  class EditWindowTermbox < EditWindow
    def initialize(frame, buffer, left, top, width, height)
      super(frame, buffer, left, top, width, height)
      @sci = Scintilla::ScintillaTermbox2.new do |scn|
        # code = scn['code']
        # @frame.sci_notifications.delete_if { |n| n['code'] == code }
        @frame.sci_notifications.push(scn)
      end

      compute_area
      init_sci_default
      init_margin_termbox
      init_buffer(buffer)
      @mode_win = ModeWindowTermbox.new
      focus_in
      # @sci.sci_set_focus(true)
      # @sci.refresh
    end

    def init_margin_termbox
      set_margin
      @sci.sci_set_margin_maskn(MARGIN_LINE_NUMBER, MARKERMASK_LINE_NUMBER)
      @sci.sci_set_margin_widthn(MARGIN_FOLDING, 2)
      @sci.sci_set_margin_typen(MARGIN_FOLDING, 0)
    end

    def to_rgb(color)
      ((color & 0xff) << 16) + (color & 0x00ff00) + ((color & 0xff0000) >> 16)
    end

    def apply_theme(theme)
      apply_theme_base(theme)
      @sci.sci_set_fold_margin_colour(true, theme.background_color)
      @sci.sci_set_fold_margin_hicolour(true, theme.foreground_color)
      (25..31).each do |n|
        @sci.sci_marker_set_fore(n, theme.foreground_color)
        @sci.sci_marker_set_back(n, theme.background_color)
      end
      if theme.font_color[:color_mode_line]
        @mode_win.fore_color = to_rgb(theme.font_color[:color_mode_line][0])
        @mode_win.back_color = to_rgb(theme.font_color[:color_mode_line][1])
      end
      if theme.font_color[:color_mode_line_inactive]
        @mode_win.fore_color_inactive = to_rgb(theme.font_color[:color_mode_line_inactive][0])
        @mode_win.back_color_inactive = to_rgb(theme.font_color[:color_mode_line_inactive][1])
      end
    end

    def compute_area
      @width = @x2 - @x1 + 1
      @height = @y2 - @y1 + 1
      @sci.move(@x1, @y1)
      @sci.resize(@width, @height - 1)
    end

    def refresh
      @sci.refresh
    end

    def refresh_modeline
      is_focus = @sci.sci_get_focus
      fore_color = is_focus ? @mode_win.fore_color : @mode_win.fore_color_inactive
      back_color = is_focus ? @mode_win.back_color : @mode_win.back_color_inactive
      Termbox2.print(@x1, @y2, fore_color, back_color, @mode_win.mode_str)
    end

    def focus_out
      super
      refresh_modeline
    end
  end
end
