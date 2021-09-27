require 'strscan'

module Yatom
  Token = Struct.new(:tag, :value, :lineno, :column)

  class SyntaxError < ::RuntimeError
    def initialize(filename, lineno, column, message)
      super "#{filename}:#{lineno}:#{column}: #{message}"
      @filename = filename
      @lineno = lineno
      @column = column
    end

    attr_reader :filename, :lineno, :column
  end

  class Lexer
    def initialize(src, file, line = 1)
      @s = StringScanner.new(src.encode(Encoding::UTF_8).chomp + "\n")
      @file = file
      @lineno = line
      @fib = Fiber.new(&method(:lex_loop))
      @last_pos = 0
      @last_tag = nil
      @loc_memo = {}
    end

    def next_token
      @fib.resume
    end

    private

    def calc_location(pos)
      @loc_memo[pos] ||= begin
        part = @s.string[0...pos]
        bol = part.rindex("\n").then{ _1 ? _1 + 1 : 0 }
        [part.count("\n") + 1, pos - bol + 1]
      end
    end

    def syntax_error(msg)
      line, col = calc_location(@last_pos)
      raise SyntaxError.new(@file, line, col, msg)
    end

    def emit(tag = @s.matched, val = @s.matched, pos = @last_pos)
      @last_tag = tag
      Fiber.yield Token.new(tag, val, *calc_location(pos))
    end

    def scan(re)
      @last_pos = @s.pos
      @s.scan(re)
    end

    def lex_loop
      meth = :lex_default
      meth = send(meth) until @s.eos?
      emit :EOF, nil, @s.pos
    end

    StringBuilder = Struct.new(:content, :beg)

    def lex_default
      case
      when scan(/"/)
        @string = StringBuilder.new(String.new, @last_pos)
        return :lex_basic_string
      when scan(/\w+/)
        emit :BARE_KEY
      else
        raise Exception, "must not happen: #{@s.rest}"
      end
      __method__
    end

    ESC = {
      'b' => "\u0008",
      't' => "\u0009",
      'n' => "\u000A",
      'f' => "\u000C",
      'r' => "\u000D",
      '"' => "\u0022",
      '\\' => "\u005C",
    }

    def lex_basic_string
      case
      when scan(/\n/)
        syntax_error "unterminated basic string"
      when scan(/[\u0000-\u0008\u000A-\u001F\u007F]/)
        syntax_error "invalid character - U+%04X" % @s.matched.ord
      when scan(/\\u([\da-fA-F]{4})/), scan(/\\U([\da-fA-F]{8})/)
        @string.content << Kernel.Integer("0x#{@s[1]}").chr
      when scan(/\\(.)/)
        @string.content << ESC.fetch(@s[1]){ syntax_error "invalid escape sequence - #{@s.matched}" }
      when scan(/"/)
        emit :BASIC_STRING, @string.content.freeze, @string.beg
        return :lex_default
      when scan(/./)
        @string.content << @s.matched
      else
        raise Exception, "must not happen: #{@s.rest}"
      end
      __method__
    end
  end
end

