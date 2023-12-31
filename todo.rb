require "sinatra"
require "sinatra/reloader" if development?
require "sinatra/content_for"
require "tilt/erubis"

require_relative "./resources/todolist.rb"
require_relative "./resources/messages.rb"

configure do
  enable :sessions
  # set :session_secret, "secret"
  set :session_secret, SecureRandom.hex(32)
  set :erb, :escape_html => true
end

before do
  session[:lists] ||= {}
  session[:messages] ||= []
end

# View helpers
helpers do
  # escape html
  # def h(text)
  #   Rack::Utils.escape_html(text)
  # end

  # def hattr(text)
  #   Rack::Utils.escape_path(text)
  # end

  def css_class(element)
    if element.done?
      "complete"
    end
  end

  def sort_by_done(list)
    undone, done = list.partition { |item| !item.done? }
    undone + done
  end
end

def get_list(list_id)
  list_id = list_id.to_i if list_id.instance_of?(String) && !list_id.empty?
  list = session[:lists][list_id]
  return list if list

  session[:messages] << ErrorMessage.new("List does not exist.")
  redirect "/lists"
end

# Homepage redirection
get "/" do
  redirect "/lists"
end

# Display list of todo lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Display form for new todo list creation
get "/lists/new" do
  erb :new_list, layout: :layout
end

def error_for_list_name(list_name)
  if !(1..100).include?(list_name.size)
    ErrorMessage.new("List name must be between 1 and 100 characters.")
  elsif session[:lists].values.any? { |list| list.name == list_name }
    ErrorMessage.new("List name must be unique.")
  end
end

# Create a new todo list
post "/lists" do
  list_name = params[:list_name].strip

  error = error_for_list_name(list_name)
  if error
    session[:messages] << error
    erb :new_list, layout: :layout
  else
    new_list = TodoList.new(list_name) 
    session[:lists][new_list.id] = new_list
    session[:messages] << SuccessMessage.new("The list has been created.")
    redirect "/lists"
  end
end

# Display a todo list
get "/lists/:list_id" do |list_id|
  @list = get_list(list_id)

  erb :list, layout: :layout
end

# Edit an existing todo list
get "/lists/:list_id/edit" do |list_id|
  @list = get_list(list_id)

  erb :edit_list
end

# Update an existing todo list
post "/lists/:list_id" do |list_id|
  @list = get_list(list_id)
  new_list_name = params[:list_name].strip

  error = error_for_list_name(new_list_name)
  if error
    session[:messages] << error
    erb :edit_list, layout: :layout
  else
    @list.name = new_list_name
    session[:messages] << SuccessMessage.new("The list has been updated.")
    redirect "/lists/#{list_id}"
  end
end

# Delete a list
post "/lists/:list_id/destroy" do |list_id|
  @list_id = list_id.to_i
  session[:lists].delete(@list_id)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:messages] << SuccessMessage.new("The list has been deleted.")
    redirect "/lists"
  end
end

def error_for_todo_name(todo_name)
  if !(1..100).include?(todo_name.size)
    ErrorMessage.new("Todo name must be between 1 and 100 characters.")
  end
end

# Add a new todo item to the list
post "/lists/:list_id/todos" do |list_id|
  @list = get_list(list_id)
  todo_name = params[:todo].strip

  error = error_for_todo_name(todo_name)
  if error
    session[:messages] << error
    erb :list, layout: :layout
  else
    @list << Todo.new(todo_name)
    session[:messages] << SuccessMessage.new("The todo has been added.")
    redirect "/lists/#{list_id}"
  end
end

# Mark a todo done or undone
post "/lists/:list_id/todos/:todo_id" do |list_id, todo_id|
  todo_id = todo_id.to_i
  list = get_list(list_id)
  completed = params[:completed] == "true"
  completed ? list.mark_done_at(todo_id) : list.mark_undone_at(todo_id)
  session[:messages] << SuccessMessage.new("The todo has been updated.")
  redirect "/lists/#{list_id}"
end

# Delete a todo item
post "/lists/:list_id/todos/:todo_id/destroy" do |list_id, todo_id|
  todo_id = todo_id.to_i
  list = get_list(list_id)
  list.remove_at(todo_id)
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204 # Success - No Content
  else
    session[:messages] << SuccessMessage.new("The todo has been deleted.")
    redirect "/lists/#{list_id}"
  end
end

# Mark all todos in a list as done
post "/lists/:list_id/complete_all" do |list_id|
  list = get_list(list_id)
  msg = if list.empty?
      ErrorMessage.new("No todos in list.")
    else
      list.mark_all_done
      SuccessMessage.new("All todos have been completed.")
    end
  session[:messages] << msg
  redirect "/lists/#{list_id}"
end

not_found { redirect "/lists" }
