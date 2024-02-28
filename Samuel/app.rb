require 'slim'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'
require 'bcrypt'



  get('/')  do
    slim(:start)
  end

  get('/register') do
    slim(:"/users/register")
  end

  get('/showlogin') do
    slim(:"/users/login")
  end

  get('/wallet') do
    slim(:"/users/wallet")
  end

  get('/blackjack') do
    slim(:"/blackjack/blackjack")
  end
  
  
  post('/login') do
    username = params[:username]
    password = params[:password]
    db = SQLite3::Database.new("db/musicsite.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users WHERE username = ?",username).first
    pwdigest = result["pwdigest"]
    id = result["id"]
    
    if BCrypt::Password.new(pwdigest) == password
      session[:id] = id
      redirect('/albums')
    else
      "Fel lösenord!"
    end
  end
  
  # get('/todos') do
  #   id = session[:id].to_i
  #   db = SQLite3::Database.new("db/musicsite.db")
  #   db.results_as_hash = true
  #   result = db.execute("SELECT * FROM todos WHERE user_id = ?",id)
  #   p "Alla todos från result #{result}"
  #   slim(:"todos/index",locals:{todos:result})
  # end
  
  post('/users/new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
  
    if (password == password_confirm)
      password_digest = BCrypt::Password.create(password)
      db = SQLite3::Database.new("db/musicsite.db")
      db.execute("INSERT INTO users (username, pwdigest) VALUES (?,?)",username,password_digest)
      redirect('/')
    else
      "Lösenorden matchar inte!"
    end
  end




  
  get('/albums') do
    db = SQLite3::Database.new("db/musicsite.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM albums")
    p result
    slim(:"albums/index",locals:{albums:result})
  end
  
  get('/albums/new') do
    slim(:"albums/new")
  end
  
  post('/albums/new') do
    title = params[:title]
    artist_id = params[:artist_id].to_i
    p "vi fick datan #{title} och #{artist_id}"
    db = SQLite3::Database.new("db/musicsite.db")
    db.execute("INSERT INTO albums (Title, ArtistId) VALUES (?,?)",title, artist_id)
    redirect('/albums')
  end
  
  post('/albums/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/musicsite.db")
    db.execute("DELETE FROM albums WHERE AlbumId = ?",id)
    redirect('/albums')
  end
  
  post('/albums/:id/update') do
    id = params[:id].to_i
    title = params[:title]
    artist_id = params[:artistId].to_i
    db = SQLite3::Database.new("db/musicsite.db")
    db.execute("UPDATE albums SET Title=?,ArtistId=? WHERE AlbumId = ?",title,artist_id,id)
    redirect('/albums')
  end
  
  get('/albums/:id/edit') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/musicsite.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM albums WHERE AlbumId = ?",id).first
    slim(:"/albums/edit",locals:{result:result})
  end
  
  get('/albums/:id') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/musicsite.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM albums WHERE AlbumId = ?",id).first
    result2 = db.execute("SELECT Name FROM Artists WHERE ArtistId IN (SELECT ArtistId FROM Albums WHERE AlbumId = ?)",id).first
    p "Resultat2 är: #{result2}"
    slim(:"albums/show",locals:{result:result,result2:result2})
  end
  
  
  