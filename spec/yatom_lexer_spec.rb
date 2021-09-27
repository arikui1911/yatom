require 'yatom/lexer'

RSpec.describe Yatom::Lexer do
  context '#next_token' do
    it 'ベア・キー' do
      lexer = Yatom::Lexer.new('hoge', '-')
      expect(lexer.next_token).to have_attributes(tag: :BARE_KEY, value: 'hoge', lineno: 1, column: 1)
    end

    context '基本文字列' do
      it 'ふつうの内容' do
        lexer = Yatom::Lexer.new('"hoge"', '-')
        expect(lexer.next_token).to have_attributes(tag: :BASIC_STRING, value: 'hoge', lineno: 1, column: 1)
      end

      context 'エスケープシーケンス' do
        it '短縮形' do
          lexer = Yatom::Lexer.new('"\b\t\n\f\r\"\\\\"', '-')
          expect(lexer.next_token).to have_attributes(tag: :BASIC_STRING, value: "\u0008\u0009\u000A\u000C\u000D\u0022\u005C", lineno: 1, column: 1)
        end

        it 'Unicodeスカラ4ケタ' do
          lexer = Yatom::Lexer.new('"\u0061"', '-')
          expect(lexer.next_token).to have_attributes(tag: :BASIC_STRING, value: 'a', lineno: 1, column: 1)
        end

        it 'Unicodeスカラ8ケタ' do
          lexer = Yatom::Lexer.new('"\U00000061"', '-')
          expect(lexer.next_token).to have_attributes(tag: :BASIC_STRING, value: 'a', lineno: 1, column: 1)
        end
      end

      it '途中で改行はできない' do
        lexer = Yatom::Lexer.new('"hoge', '-')
        expect{ lexer.next_token }.to raise_error(Yatom::SyntaxError)
      end

      context '有効でないUTF-8文字を含む' do
        let(:src){ %Q`"ho#{ch}ge"` }
        subject{ Yatom::Lexer.new(src, '-').next_token }
        shared_examples :on_invalid_char do
          # NOTE: is_expected を使うと例外が補足できない
          it { expect{ subject }.to raise_error(Yatom::SyntaxError) }
        end

        invalid_chars = [
          "\u0000", "\u0001", "\u0002", "\u0003", "\u0004", "\u0005", "\u0006", "\u0007", "\u0008",
          "\u000A", "\u000B", "\u000C", "\u000D", "\u000E", "\u000F",
          "\u0010", "\u0011", "\u0012", "\u0013", "\u0014", "\u0015", "\u0016", "\u0017", "\u0018", "\u0019", 
          "\u001A", "\u001B", "\u001C", "\u001D", "\u001E", "\u001F",
          "\u007F",
        ]

        invalid_chars.each do |ch|
          context 'U+%04X' % ch.ord do
            let(:ch){ ch }
            it_behaves_like :on_invalid_char
          end
        end
      end
    end
  end
end

