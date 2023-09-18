# This class represents a todo item and its associated
# data: name and description. There's also a "done"
# flag to show whether this todo item is done.

class Todo
  attr_accessor :name, :description, :done

  def initialize(name, description = '')
    @name = name
    @description = description
    @done = false
  end

  def done!
    self.done = true
  end

  def done?
    done
  end

  def undone!
    self.done = false
  end

  def to_s
    name
  end

  def ==(otherTodo)
    name == otherTodo.title && description == otherTodo.description &&
      done == otherTodo.done
  end
end

# This class represents a collection of Todo objects.
# You can perform typical collection-oriented actions
# on a TodoList object, including iteration and selection.

class TodoList
  attr_accessor :name

  def initialize(name)
    @name = name
    @todos = []
  end

  def <<(todo)
    raise TypeError.new('Can only add Todo objects') unless todo.is_a?(Todo)
    todos << todo
  end

  alias_method :add, :<<

  def size
    todos.size
  end

  def empty?
    self.size == 0
  end

  def first
    todos.first
  end

  def last
    todos.last
  end

  def to_a
    todos.dup
  end

  def done?
    !self.empty? && todos.all?(&:done?)
  end

  def item_at(i)
    raise IndexError if i >= todos.size
    todos[i]
  end

  def mark_done_at(i)
    item_at(i).done!
  end

  def mark_undone_at(i)
    item_at(i).undone!
  end

  def done!
    todos.each(&:done!)
  end

  def shift
    todos.shift
  end

  def pop
    todos.pop
  end

  def remove_at(i)
    raise IndexError if i >= todos.size
    todos.delete_at(i)
  end

  def to_s
    # str = '-' * 4 + name + '-' * 4 + "\n"
    # str << todos.map(&:to_s).join("\n")
    name + ": " + todos.map(&:to_s).join(", ")
  end

  def each
    todos.each { |todo| yield(todo) }
    self
  end

  def each_with_index
    if block_given?
      todos.each_with_index { |todo, i| yield(todo, i) }
      self
    else
      todos.each_with_index
    end
  end

  def select
    # res = []
    # todos.each { |todo| res << todo if yield(todo) }

    res = TodoList.new(name)
    self.each { |todo| res.add(todo) if yield(todo) }
    res
  end

  def find_by_name(name)
    self.each { |todo| return todo if todo.name == name }
    nil
  end

  def all_done
    self.select(&:done)
  end

  def all_not_done
    self.select { |todo| !todo.done }
  end

  def mark_done(name)
    todo = self.find_by_name(name)
    todo.done! if todo
    self
  end

  def mark_all_done
    self.each(&:done!)
  end

  def mark_all_undone
    self.each(&:undone!)
  end

  protected

  attr_accessor :todos
end
