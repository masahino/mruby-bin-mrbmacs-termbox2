module Mrbmacs
  # Modeline
  class ModeWindowTermbox
    attr_accessor :mode_str, :fore_color,
                  :back_color, :fore_color_inactive, :back_color_inactive

    def initialize
      @mode_str = ''
      @fore_color = 0x181818
      @back_color = 0xb8b8b8
      @fore_color_inactive = 0xb8b8b8
      @back_color_inactive = 0x585858
    end

    def update(str)
      @mode_str = str
    end
  end
end
