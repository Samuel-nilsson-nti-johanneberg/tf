require 'slim'
require 'sinatra'
require 'sinatra/reloader'
require_relative './model.rb'

enable :sessions

before do
    @db = SQLite3::Database.new("db/musicsite.db")
    @db.results_as_hash = true
end

get('/') do
    if session[:id] != nil
    
        if check_admin(session[:id])
            slim(:"/start_admin")
        else
            slim(:"/start2")
        end
    else
        slim(:"/start")
    end
end

get('/register') do
    slim(:"/users/register")
end

get('/showlogin') do
    slim(:"/users/login")
end

get('/response10') do
    slim(:"/responses/response10")
end

get('/response11') do
    slim(:"/responses/response11")
end


post('/login') do
    username = params[:username]
    password = params[:password]
    result = login(username)

    if result != nil
    pwdigest = result["Pwdigest"]
    id = result["Userid"]
    if BCrypt::Password.new(pwdigest) == password
        session[:id] = id
        session[:result] = result
        redirect('/')
    else
        session[:response_code] = 10
        redirect('/login_response')
    end
    else 
    session[:response_code] = 11
    redirect('/login_response')
    end
end

get('/login_response') do
    @response_code = session.delete(:response_code)
    slim(:"responses/login_response",locals:{response_code:@response_code})
end

get('/wallet') do
    if session[:id] != nil
        slim(:"/users/wallet")
    else
        slim(:"/users/login")
    end
end

post('/wallet/add100') do
    session[:result]["Wallet"] += 100
    save_wallet(session[:result])
    redirect('/wallet')
end

post('/wallet/add500') do
    session[:result]["Wallet"] += 500
    save_wallet(session[:result])
    redirect('/wallet')
end

post('/wallet/add1000') do
    session[:result]["Wallet"] += 1000
    save_wallet(session[:result])
    redirect('/wallet')
end

get('/response20') do
    slim(:"responses/response20")
end

get('/response21') do
    slim(:"responses/response21")
end

get('/response22') do
    slim(:"responses/response22")
end

get('/response23') do
    slim(:"responses/response23")
end

get('/response24') do
    slim(:"responses/response24")
end

post('/users/new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    firstname = params[:firstname]
    lastname = params[:lastname]
    email = params[:email]

    if username.length < 5 || username.nil?
        session[:response_code] = 20
        redirect('/registration_response')
    else
        if !check_username(username)
        session[:response_code] = 21
        redirect('/registration_response')
        end
    end

    if !email.include?("@") || !email.include?(".")
        session[:response_code] = 22
        redirect('/registration_response')
    else
        if !check_email(email)
        session[:response_code] = 23
        redirect('/registration_response')
        end
    end

    if password != password_confirm
        session[:response_code] = 24
        redirect('/registration_response')
    end

    register_user(username, password, firstname, lastname, email)
    redirect('/')
end
  
get('/registration_response') do
    @response_code = session.delete(:response_code)
    slim(:"responses/registration_response",locals:{response_code:@response_code})
end
  

get('/store') do
    result = @db.execute("SELECT * FROM albums")
    # if check_admin(session[:id])
    #     slim(:"albums_admin/store",locals:{albums:result})
    # end
    slim(:"albums/store",locals:{albums:result})
    
end

get('/response1') do
    slim(:"responses/response1")
end

get('/response2') do
    slim(:"responses/response2")
end

get('/response3') do
    slim(:"responses/response3")
end

get('/response4') do
    slim(:"responses/response4")
end

get('/albums') do
    
    albums_result = @db.execute("SELECT * FROM albums")
    rel_result = @db.execute("SELECT * FROM user_album_rel")
    UserId = session[:result]["Userid"]
    
    result = []
    rel_result.each do |row|
        row_userid = row[0] 
        row_albumid = row[1]
        if row_userid == UserId
            result << albums_result[row_albumid-1]
        end
  end

  slim(:"albums/index",locals:{albums:result})
end

post('/albums/:id/purchase') do
    id = params[:id].to_i
    session_result = session[:result]

    response = purchase_album(id, session_result)
    
    if response == "response1"
        session[:response_code] = 1
        redirect('/wallet_response')
    elsif response == "response2"
        session[:response_code] = 2
        redirect('/wallet_response')
    elsif response == "response3"
        session[:response_code] = 3
        redirect('/wallet_response')
    end
end

get('/wallet_response') do
    @response_code = session.delete(:response_code)
    slim(:"responses/wallet_response",locals:{response_code:@response_code})
end
  

post('/albums/:id/refund') do
    id = params[:id].to_i
    session_result = session[:result]
    refund_album(id, session_result)
    redirect('/response4')
end

# get('/store_admin') do
#     db = SQLite3::Database.new("db/musicsite.db")
#     db.results_as_hash = true
#     result = db.execute("SELECT * FROM albums")
#     slim(:"albums_admin/store",locals:{albums:result})
# end
  
# get('/store_admin/:id/edit') do
#     id = params[:id].to_i
#     db = SQLite3::Database.new("db/musicsite.db")
#     db.results_as_hash = true
#     result = db.execute("SELECT * FROM albums WHERE AlbumId = ?",id).first
#     slim(:"/albums_admin/edit",locals:{result:result})
#   end

