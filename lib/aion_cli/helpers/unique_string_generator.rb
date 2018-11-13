class UniqueStringGenerator

  def initialize(used_values = [], &block)
    @used_values = Set.new(used_values)
    @block = block
  end

  def get
    loop do
      code = @block.call
      next if @used_values.include?(code)
      @used_values.add(code)
      return code
    end
  end

end