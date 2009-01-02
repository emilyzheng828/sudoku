#!/usr/bin/env ruby

require 'set'

class Cell
  attr_reader :number, :groups, :row, :col

  def initialize(r,c)
    @row = r
    @col = c
    @groups = []
  end

  def number=(value)
    @number = value.nonzero?
  end

  def available_numbers
    return Set[] if number
    result = Set[*(1..9)]
    @groups.each do |g|    
      result -= g.numbers
    end
    result
  end

  def join(group)
    @groups << group
  end

  def to_s
    "C#{@row}#{@col}"
  end

  def inspect
    to_s
  end
end

# A group of cells.
class Group
  def initialize
    @cells = []
  end

  def <<(cell)
    cell.join(self)
    @cells << cell
    self
  end

  def numbers
    @cells.inject(Set.new) { |res, c| c.number ? (res << c.number) : res }
  end

  def to_s
    "G"
  end

  def inspect
    to_s
  end
end

class Grid
  include Enumerable

  def initialize(verbose=nil)
    @verbose = verbose
    @cells = (0..8).map { |c|
      (0..8).map { |r|
        Cell.new(r,c)
      }
    }
    define_groups
  end

  def parse(string)
    numbers = string.gsub(/\n/, '').split(//).map { |n| n.to_i }
    each do |cell, r, c|
      cell.number = numbers.shift
    end
    self
  end

  def each
    @cells.each do |row|
      row.each do |cell|
        yield cell
      end
    end
  end

  def solved?
    all? { |cell| cell.number }
  end

  def stuck?
    any? { |cell| cell.number.nil? && cell.available_numbers.size == 0 }
  end
  
  def solve
    retries = []
    while true
      while solve_one_square
      end
      return if solved?
      if stuck?
        fail "No Solution Found" if retries.empty?
        puts "Backtracking (#{retries.size})" if @verbose
        guess(retries)
      else
        cell = to_a.reject { |cell|
          cell.number
        }.sort_by { |cell| 
          cell.available_numbers.size
        }.first
        cell.available_numbers.each do |n|
          retries.push([number_string, cell, n])
        end
        guess(retries)
      end
    end
  end

  def guess(retries)
    state, cell, number = retries.pop
    parse(state)
    puts "Guessing #{number} at #{cell}" if @verbose
    cell.number = number        
  end

  def solve_one_square
    each do |cell|
      an = cell.available_numbers
      if an.size == 1
        puts "Put #{an.to_a.first} at (#{cell})" if @verbose
        cell.number = an.to_a.first
        return true
      end
    end
    return false
  end
  
  def to_s
    number_string.
      gsub(/.../, "\\0 ").
      gsub(/.{12}/, "\\0\n").
      gsub(/.{39}/m, "\\0\n").
      gsub(/[\d.]/, "\\0 ")
  end

  def inspect
    "<Grid #{number_string}>"
  end

  def number_string
    map { |cell|
      cell.number ? cell.number.to_s : "."
    }.join("")
  end

  def [](row,col)
    @cells[row][col]
  end

  private

  def define_groups
    define_columns
    define_rows
    define_blocks
  end

  def define_rows
    (0..8).each do |r|
      define_group(r..r, 0..8)
    end
  end

  def define_columns
    (0..8).each do |c|
      define_group(0..8, c..c)
    end
  end

  def define_blocks
    [(0..2), (3..5), (6..8)].each do |rrange|
      [(0..2), (3..5), (6..8)].each do |crange|
        define_group(rrange, crange)
      end
    end
  end

  def define_group(row_range, col_range)
    g = Group.new
    row_range.each do |r|
      col_range.each do |c|
        g << self[r,c]
      end
    end
  end
  
end

# http://en.wikipedia.org/wiki/Sudoku
Wiki =
  "53  7    " +
  "6  195   " +
  " 98    6 " +
  "8   6   3" +
  "4  8 3  1" +
  "7   2   6" +
  " 6    28 " +
  "   419  5" +
  "    8  79"

# http://www.websudoku.com/?level=2&set_id=3350218628
Medium = 
  " 4   7 3 " +
  "  85  1  " +
  " 15 3  9 " +
  "5   7 21 " +
  "  6   8  " +
  " 81 6   9" +
  " 2  4 57 " +
  "  7  29  " +
  " 5 7   8 "

# http://www.websudoku.com/?level=4&set_id=470872047
Evil = 
  "  53 694 " +
  " 3 1    6" +
  "       3 " +
  "7  9     " +
  " 1  3  2 " +
  "     2  7" +
  " 6       " +
  "8    7 5 " +
  " 436 81  "

if __FILE__ == $0 then
  def solve(string)
      puts "Solving ----------------------------------------------------"
      grid = Grid.new(true)
      grid.parse(string)
      puts grid
      
      grid.solve
      puts
      puts grid
      puts
  end

  if ARGV.empty?
    [Wiki, Medium, Evil].each do |s|
      solve(s)
    end
  else
    ARGV.each do |fn|
      open(fn) do |f|
        solve(f.read)
      end
    end
  end
end
