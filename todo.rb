require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

require_relative './resources/todolist.rb'
require_relative './resources/messages.rb'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before do
  session[:lists] ||= []
  session[:messages] ||= []
end

get '/' do
  redirect '/lists'
end

# Display list of todo lists
get '/lists' do
  @button = 'add'
  @button_link = '/lists/new'
  @button_text = 'New List'
  @lists = session[:lists]
  erb :lists, layout: :layout
end
set :session_secret, SecureRandom.hex(32)

# Render new todo list form
get '/lists/new' do
  erb :new_list, layout: :layout
end

def error_for_list_name(list_name)
  if !(1..100).include?(list_name.size)
    ErrorMessage.new('List name must be between 1 and 100 characters.')
  elsif session[:lists].any? { |list| list.name == list_name }
    ErrorMessage.new('List name must be unique.')
  end
end

# Create a new todo list
post '/lists' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)

  if error
    session[:messages] << error
    erb :new_list, layout: :layout
  else
    session[:lists] << TodoList.new(list_name) #{ name: list_name, todos: [] }
    session[:messages] << SuccessMessage.new('The list has been created.')
    redirect '/lists'
  end
end

get '/lists/:list_id' do |list_id|
  @button = 'list'
  @button_link = '/lists'
  @button_text = 'All Lists'
  @list_id = list_id.to_i
  @list = session[:lists][@list_id]

  # ['eat nachos', 'pet dog', 'punch a kangaroo'].each do |item|
  #   @list << Todo.new(item) if @list.size < 3
  # end
  erb :list
end

post '/lists/:list_id' do |list_id|
  @list_id = list_id.to_i
  @list = session[:lists][@list_id]
  new_list_name = params[:list_name].strip
  error = error_for_list_name(new_list_name)

  if error
    session[:messages] << error
    erb :edit_list, layout: :layout
  else
    @list.name = new_list_name
    session[:messages] << SuccessMessage.new('The list has been created.')
    redirect "/lists/#{@list_id}"
  end
end

def error_for_todo_name(todo_name)
  if !(1..100).include?(todo_name.size)
    ErrorMessage.new('Todo name must be between 1 and 100 characters.')
  end
end

post '/lists/:list_id/todos' do |list_id|
  @list_id = list_id.to_i
  @list = session[:lists][@list_id]
  todo_name = params[:todo]

  error = error_for_todo_name(todo_name)
  if error
    session[:messages] << error
    erb :new_list
  else
    @list << Todo.new(todo_name)
    session[:messages] << SuccessMessage.new('The todo has been added.')
    redirect "/lists/#{list_id}"
  end
end

post '/lists/:list_id/todos/:todo_id' do |list_id, todo_id|
  @list_id, @todo_id = [list_id, todo_id].map(&:to_i)
  @list = session[:lists][@list_id]
  completed = (params[:completed] == 'true')
  completed ? @list.mark_done_at(@todo_id) : @list.mark_undone_at(@todo_id)
  session[:messages] << SuccessMessage.new('The todo has been updated.')
  redirect "/lists/#{@list_id}"
end

post '/lists/:list_id/todos/:todo_id/destroy' do |list_id, todo_id|
  @list_id, @todo_id = [list_id, todo_id].map(&:to_i)
  @list = session[:lists][@list_id]
  @list.remove_at(@todo_id)
  session[:messages] << SuccessMessage.new('The todo has been deleted.')
  redirect "/lists/#{@list_id}"
end

post '/lists/:list_id/complete_all' do |list_id|
  @list_id = list_id.to_i
  @list = session[:lists][@list_id]
  @list.mark_all_done
  session[:messages] << SuccessMessage.new('All todos have been completed.')
  redirect "/lists/#{@list_id}"
end

get '/lists/:list_id/edit' do |list_id|
  @list_id = list_id.to_i
  @list = session[:lists][@list_id]

  erb :edit_list
end

post '/lists/:list_id/destroy' do |list_id|
  @list_id = list_id.to_i
  session[:lists].delete_at(@list_id)

  session[:messages] << SuccessMessage.new('The list has been deleted.')
  redirect '/lists'
end

not_found { redirect '/lists' }
