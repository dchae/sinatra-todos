require 'sinatra'
require 'sinatra/reloader'
require 'tilt/erubis'

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

# Create a new todo list
post '/lists' do
  session[:lists] << { name: params[:list_name], todos: [] }
  session[:success] = "The list has been created."
  redirect '/lists'
end


get '/lists/:list_id' do |list_id|

end

get '/lists/:list_id/todos/todo_id' do |list_id, todo_id|

end