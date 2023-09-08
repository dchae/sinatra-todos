require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

require_relative './resources/todolist.rb'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

before { session[:lists] ||= [] }

get '/' do
  redirect '/lists'
end

# Display list of todo lists
get '/lists' do
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
    'List name must be between 1 and 100 characters.'
  elsif session[:lists].any? { |list| list.name == list_name }
    'List name must be unique.'
  end
end

# Create a new todo list
post '/lists' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)

  if error
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << TodoList.new(list_name) #{ name: list_name, todos: [] }
    session[:success] = 'The list has been created.'
    redirect '/lists'
  end
end

get '/lists/:list_id' do |list_id|
  @list_id = list_id.to_i
  @list = session[:lists][@list_id]
  ['eat nachos', 'pet dog', 'punch a kangaroo'].each do |item|
    @list << Todo.new(item) if @list.size < 3
  end
  erb :list
end

def error_for_todo_name(todo_name)
  if !(1..100).include?(todo_name.size)
    'Todo name must be between 1 and 100 characters.'
  end
end

post '/lists/:list_id/todos' do |list_id|
  @list_id = list_id.to_i
  @list = session[:lists][@list_id]
  todo_name = params[:todo]

  error = error_for_todo_name(todo_name)
  if error
    session[:error] = error
    erb :new_list
  else
    @list << Todo.new(todo_name)
    redirect "/lists/#{list_id}"
  end
end

post '/lists/:list_id/todos/:todo_id' do |list_id, todo_id|
  @list_id, @todo_id = [list_id, todo_id].map(&:to_i)
  @list = session[:lists][@list_id]
  completed = (params[:completed] == 'true')
  completed ? @list.mark_done_at(@todo_id) : @list.mark_undone_at(@todo_id)
  redirect "/lists/#{@list_id}"
end

post '/lists/:list_id/todos/:todo_id/destroy' do |list_id, todo_id|
  @list_id, @todo_id = [list_id, todo_id].map(&:to_i)
  @list = session[:lists][@list_id]
  @list.remove_at(@todo_id)
  redirect "/lists/#{@list_id}"
end

not_found { redirect '/lists' }
