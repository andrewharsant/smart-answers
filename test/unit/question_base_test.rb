require_relative '../test_helper'

class QuestionBaseTest < ActiveSupport::TestCase
  setup do
    @question = SmartAnswer::Question::Base.new(nil, :example_question)
  end

  context '#next_node' do
    should 'raise exception if called with block but no permitted next nodes' do
      e = assert_raises(ArgumentError) do
        @question.next_node do
          :done
        end
      end
      assert_equal 'You must specify at least one permitted next node', e.message
    end

    should 'single next node key must be supplied if next_node called without block' do
      e = assert_raises(ArgumentError) do
        @question.next_node
      end
      assert_equal 'You must specify a block or a single next node key', e.message
    end

    should 'raise exception if next_node is invoked multiple times' do
      e = assert_raises do
        @question.next_node :outcome_one
        @question.next_node :outcome_two
      end
      assert_equal 'Multiple calls to next_node are not allowed', e.message
    end
  end

  context '#permitted_next_nodes' do
    should 'return permitted next nodes if next_node called with block' do
      @question.next_node(permitted: [:done]) do
        :done
      end
      assert_equal [:done], @question.permitted_next_nodes
    end

    should 'return permitted next nodes if next_node called without block' do
      @question.next_node :done
      assert_equal [:done], @question.permitted_next_nodes
    end
  end

  context '#transition' do
    should "copy values from initial state to new state" do
      @question.next_node :done
      initial_state = SmartAnswer::State.new(@question.name)
      initial_state.something_else = "Carried over"
      new_state = @question.transition(initial_state, :yes)
      assert_equal "Carried over", new_state.something_else
    end

    should "set current_node to value returned from next_node_for" do
      @question.next_node :done
      initial_state = SmartAnswer::State.new(@question.name)
      @question.stubs(:next_node_for).returns(:done)
      new_state = @question.transition(initial_state, :anything)
      assert_equal :done, new_state.current_node
    end

    should "set current_node to node key passed into next_node method" do
      @question.next_node :done
      initial_state = SmartAnswer::State.new(@question.name)
      new_state = @question.transition(initial_state, :anything)
      assert_equal :done, new_state.current_node
    end

    should "set current_node to result of calling next_node block" do
      @question.next_node(permitted: [:done_done]) { :done_done }
      initial_state = SmartAnswer::State.new(@question.name)
      new_state = @question.transition(initial_state, :anything)
      assert_equal :done_done, new_state.current_node
    end

    should "make state available to code in next_node block" do
      permitted_next_nodes = [:was_red, :wasnt_red]
      @question.next_node(permitted: permitted_next_nodes) do
        colour == 'red' ? :was_red : :wasnt_red
      end
      initial_state = SmartAnswer::State.new(@question.name)
      initial_state.colour = 'red'
      new_state = @question.transition(initial_state, 'anything')
      assert_equal :was_red, new_state.current_node
    end

    should "pass input to next_node block" do
      input_was = nil
      @question.next_node(permitted: [:done]) do |input|
        input_was = input
        :done
      end
      initial_state = SmartAnswer::State.new(@question.name)
      new_state = @question.transition(initial_state, 'something')
      assert_equal 'something', input_was
    end

    should "make save_input_as method available to code in next_node block" do
      @question.save_input_as :colour_preference
      @question.next_node :done
      initial_state = SmartAnswer::State.new(@question.name)
      new_state = @question.transition(initial_state, :red)
      assert_equal :red, new_state.colour_preference
    end

    should "save input sequence on new state" do
      @question.next_node :done
      initial_state = SmartAnswer::State.new(@question.name)
      new_state = @question.transition(initial_state, :red)
      assert_equal [:red], new_state.responses
    end

    should "save path on new state" do
      @question.next_node :done
      initial_state = SmartAnswer::State.new(@question.name)
      initial_state.current_node = @question.name
      new_state = @question.transition(initial_state, :red)
      assert_equal [@question.name], new_state.path
    end

    should "execute calculate block with response and save result on new state" do
      @question.calculate :complementary_colour do |response|
        response == :red ? :green : :red
      end
      @question.next_node :done
      initial_state = SmartAnswer::State.new(@question.name)
      new_state = @question.transition(initial_state, :red)
      assert_equal :green, new_state.complementary_colour
      assert new_state.frozen?
    end

    should "execute calculate block with saved input and save result on new state" do
      @question.save_input_as :colour_preference
      @question.calculate :complementary_colour do
        colour_preference == :red ? :green : :red
      end
      @question.next_node :done
      initial_state = SmartAnswer::State.new(@question.name)
      new_state = @question.transition(initial_state, :red)
      assert_equal :green, new_state.complementary_colour
      assert new_state.frozen?
    end

    should "execute next_node_calculation block before next_node" do
      @question.next_node_calculation :complementary_colour do |response|
        response == :red ? :green : :red
      end
      @question.next_node_calculation :blah do
        "blah"
      end
      @question.next_node(permitted: [:done]) do
        :done if complementary_colour == :green
      end
      initial_state = SmartAnswer::State.new(@question.name)
      new_state = @question.transition(initial_state, :red)
      assert_equal :green, new_state.complementary_colour
      assert_equal "blah", new_state.blah
      assert_equal :done, new_state.current_node
    end
  end

  context '#next_node_for' do
    should "raise an exception if next_node returns key not in permitted_next_nodes" do
      permitted_next_nodes = [:allowed_next_node_1, :allowed_next_node_2]
      @question.next_node(permitted: permitted_next_nodes) { :not_allowed_next_node }
      state = SmartAnswer::State.new(@question.name)

      expected_message = "Next node (not_allowed_next_node) not in list of permitted next nodes (allowed_next_node_1 and allowed_next_node_2)"
      exception = assert_raises do
        @question.next_node_for(state, 'response')
      end
      assert_equal expected_message, exception.message
    end

    should "raise an exception if next_node does not return a node key" do
      responses = [:blue, :red]
      @question.next_node(permitted: [:skipped]) do
        :skipped if false
      end
      initial_state = SmartAnswer::State.new(@question.name)
      initial_state.responses << responses[0]
      error = assert_raises(SmartAnswer::Question::Base::NextNodeUndefined) do
        @question.next_node_for(initial_state, responses[1])
      end
      expected_message = "Next node undefined. Node: #{@question.name}. Responses: #{responses}."
      assert_equal expected_message, error.message
    end

    should "raise an exception if next_node was not called for question" do
      responses = [:blue, :red]
      initial_state = SmartAnswer::State.new(@question.name)
      initial_state.responses << responses[0]
      error = assert_raises(SmartAnswer::Question::Base::NextNodeUndefined) do
        @question.next_node_for(initial_state, responses[1])
      end
      expected_message = "Next node undefined. Node: #{@question.name}. Responses: #{responses}."
      assert_equal expected_message, error.message
    end
  end
end
