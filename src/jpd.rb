class JPD
  attr_accessor :inputs
  attr_accessor :table
  attr_accessor :outputs

  def initialize(inputs, outputs)
    @inputs = inputs
    @table = {}
    @evidence = "__pgm-ev"
    @outputs = outputs

    tables = [@table]
    next_tables = []
    for i in inputs
      for iv in i
        for t in tables
          n = {}
          t[iv] = n
          next_tables << n
        end
      end
      tables = next_tables
      next_tables = {}
    end

    starting_p = 1.0 / outputs.length
    for t in tables
      t[@evidence] = 0
      for o in outputs
        t[o] = starting_p
      end
    end
  end

  # the probability of all outputs
  def output_probs(given)
    tables = dfs_for_given(given)

    op = Hash.new 0.0
    for t in tables
      for o in @outputs
        op[o] += t[o]
      end
    end

    total = 0 ; op.values.each {|e| total += e }
    for o in @outputs
      op[o] /= total
    end

    op
  end

  # sample from the output distribution
  def pull(given)
    op = output_probs(given)
    index = rand
    for o in @outputs
      index -= op[o]
      if index < 0
        return o
      end
    end
    return @outputs[-1]
  end

  def update(given, output)
    for t in dfs_for_given(given)
      e = t[@evidence] * 1.0
      em = e / (e + 1.0)
      for o in @outputs
        t[o] *= em
        t[o] += 1.0 / (e + 1.0) if o == output
      end
      t[@evidence] += 1
    end
  end

  protected
  def dfs_for_given(given)
    tables = [@table]
    next_tables = []
    for i in inputs
      for vi in i
        next unless !given || !given[i] || given[i].empty? || given[i].include?(vi)
        for t in tables
          next_tables << t[vi]
        end
      end
      tables = next_tables
      next_tables = {}
    end
    tables
  end
end

def assert_equal(expected, got)
  unless expected == got
    puts "TEST FAIL: expected #{expected.inspect}, got #{got.inspect}"
  end
end
