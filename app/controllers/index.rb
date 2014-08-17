#----------- INDEX -----------

get '/' do
  # render home page
  @users = User.all
  session[:current_results] = []
  p session
  p current_user
  erb :index
end


#----------- SESSIONS -----------

post '/sessions/error' do
  if params[:signin] == "Sign In"
    user = User.find_by(email: params[:user][:email])
    if user && user.authenticate(params[:user][:password])
    # successfully authenticated; set up session and redirect
      session[:user_id] = user.id
      redirect '/'
    else
      @error = "Invalid email or password"# an error occurred, re-render the sign-in form, displaying an error
      erb :index
    end
  elsif params[:signin] == "Sign Up"
    generate_new_user
    if @user.save
    # successfully created new account; set up the session and redirect
      session[:user_id] = @user.id
      redirect '/'
    else
      @error = "E-mail is already taken"
      erb :index
    end
  end
end

delete '/sessions/:id' do
  # sign-out -- invoked via AJAX
  return 401 unless params[:id].to_i == session[:user_id].to_i
  session.clear
  200
end


#----------- USERS -----------

get '/users/:user_id' do
  @user = User.find(params[:user_id])
  @results = @user.results

  erb :'users/show'
end


#----------- RESULTS -----------

post '/result/show' do
  @result = Result.find_or_initialize_by(topic: params[:criteria])
  if @result.new_record?
    @result.update_attributes(
      topic: params[:criteria],
      file_data: get_fda_data(params[:criteria]),
      user_id: session[:user_id]
    )
  end
  if !session[:current_results]
    session[:current_results] = [@result.id]
  else
    session[:current_results] << @result.id
  end
  session[:current_results].uniq!
  p session
  @result.to_json
end

get '/users/:user_id/results/:result_id' do
  @result = Result.find(params[:result_id])
  erb :'results/show'
end

get '/users/:user_id/results/:result_id/links' do
  redirect '/'
end



#----------- PROJECTS -------------
post '/users/:user_id/projects/new' do
  @project = Project.create(params[:project])
  if @project.valid?
    session[:current_results].each do |result_id|
      proj_res = ProjectResult.find_or_initialize_by(result_id: result_id)
      proj_res.update_attributes(project_id: @project.id, user_id: current_user.id)
      proj_res.save
    end
    session[:project_id] = @project.id
    @project.to_json
  else
    flash[:error] = @project.errors.full_messages
  end
end


post '/users/:user_id/projects/:project_id/links' do
  @project = Project.find_or_initialize(id: params[:project_id])
  @link = params[:link]
  @project.references << @link
  @project.save
  @link.to_json
end

get '/users/:user_id/projects/:project_id' do
  @project = Project.find(params[:project_id])
  @project.to_json
end
