module ISBN
  extend self
  
  def ten(isbn)
    isbn = isbn.delete("-")
    raise No10DigitISBNAvailable if isbn =~ /^979/
    isbn = isbn[/(?:978|290)*(.+)\w/,1] # remove 978, 979 or 290 and check digit
    raise Invalid10DigitISBN unless isbn.size == 9 # after removals isbn should be 9 digits
    case ck = (11 - (isbn.split(//).zip((2..10).to_a.reverse).inject(0) {|s,n| s += n[0].to_i * n[1]} % 11))
    when 10 then isbn << "X"
    when 11 then isbn << "0"
    else isbn << ck.to_s
    end
  end
  
  def thirteen(isbn)
    isbn = isbn.delete("-")
    isbn = isbn.rjust(13,"978")[/(.+)\w/,1] # adjust to 13 digit isbn and remove check digit
    raise Invalid13DigitISBN unless isbn.size == 12 # after adjustments isbn should be 12 digits
    case ck = (10 - (isbn.split(//).zip([1,3]*6).inject(0) {|s,n| s += n[0].to_i * n[1]} % 10))
    when 10 then isbn << "0"
    else isbn << ck.to_s
    end
  end

  def between_new_and_used(isbn)
    case isbn[0..2]
    when /97(8|9)/  then thirteen("290#{isbn[3..-1]}")
    when /290/      then thirteen("978#{isbn[3..-1]}")
    else isbn
    end
  end

  def valid?(isbn)
    isbn = isbn.delete("-")
    case isbn.size
    when 13 then isbn[-1] == thirteen(isbn)[-1]
    when 10 then isbn[-1] == ten(isbn)[-1]
    else raise InvalidISBNError
    end
  end
  
  def from_image(url)
    require "open-uri"
    require "tempfile"
    tmp = Tempfile.new("tmp")
    tmp.write(open(url, "rb:binary").read)
    tmp.close
    isbn = %x{djpeg -pnm #{tmp.path} | gocr -}
    isbn.strip.gsub(" ", "").gsub(/o/i, "0").gsub("_", "2").gsub(/2J$/, "45")
  end
  
  class InvalidISBNError < RuntimeError
  end
end