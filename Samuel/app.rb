require 'slim'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'
require 'bcrypt'


  enable :sessions
  

  get('/')  do
    if session[:id] != nil
      slim(:"/start2")
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
    db = SQLite3::Database.new("db/musicsite.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM users WHERE username = ?",username).first

    if result != nil
      pwdigest = result["Pwdigest"]
      id = result["Userid"]
      if BCrypt::Password.new(pwdigest) == password
        session[:id] = id
        session[:result] = result
        redirect('/')
      else
        redirect('/response10')
      end
    else 
      redirect('/response11')
    end
    

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

    wallet = session[:result]["Wallet"]
    userid = session[:result]["Userid"]
    db = SQLite3::Database.new("db/musicsite.db")
    db.execute("UPDATE users SET Wallet = #{wallet} WHERE Userid = #{userid}")
    redirect('/wallet')
  end

  post('/wallet/add500') do
    session[:result]["Wallet"] += 500
    wallet = session[:result]["Wallet"]
    userid = session[:result]["Userid"]
    db = SQLite3::Database.new("db/musicsite.db")
    db.execute("UPDATE users SET Wallet = #{wallet} WHERE Userid = #{userid}")
    redirect('/wallet')
  end

  post('/wallet/add1000') do
    session[:result]["Wallet"] += 1000
    wallet = session[:result]["Wallet"]
    userid = session[:result]["Userid"]
    db = SQLite3::Database.new("db/musicsite.db")
    db.execute("UPDATE users SET Wallet = #{wallet} WHERE Userid = #{userid}")
    redirect('/wallet')
  end

  
  post('/users/new') do
    username = params[:username]
    password = params[:password]
    password_confirm = params[:password_confirm]
    firstname = params[:firstname]
    lastname = params[:lastname]
    email = params[:email]
  
    if (password == password_confirm)
      password_digest = BCrypt::Password.create(password)
      db = SQLite3::Database.new("db/musicsite.db")
      db.execute("INSERT INTO users (Username, Pwdigest, Firstname, Lastname, Email) VALUES (?,?,?,?,?)",username,password_digest,firstname,lastname,email)
      redirect('/')
    else
      "Passwords does not match!"
    end
  end


  get('/store') do
    db = SQLite3::Database.new("db/musicsite.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM albums")
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
    db = SQLite3::Database.new("db/musicsite.db")
    db.results_as_hash = true
    albums_result = db.execute("SELECT * FROM albums")
    rel_result = db.execute("SELECT * FROM user_album_rel")
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

  post('/albums/:id/refund') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/musicsite.db")
    price = db.execute("SELECT * FROM albums WHERE AlbumId = ?",id).first[3].to_i
    price = (price/2).to_i
    UserId = session[:result]["Userid"]

    db.execute("DELETE FROM user_album_rel WHERE AlbumId = ? AND UserId = ?",id,UserId)
 
    session[:result]["Wallet"] += price
    wallet = session[:result]["Wallet"]
    db.execute("UPDATE users SET Wallet = #{wallet} WHERE Userid = #{UserId}")

    redirect('/response4')
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
  
  post('/albums/:id/purchase') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/musicsite.db")
    UserId = session[:result]["Userid"]
    wallet = session[:result]["Wallet"]
    price = db.execute("SELECT * FROM albums WHERE AlbumId = ?",id).first[3].to_i
  
    
    # Här kollar koden ifall användaren redan äger albumet han försöker köpa

    results = db.execute("SELECT * FROM user_album_rel")
    results.each do |row|
      row_userid = row[0] 
      row_albumid = row[1]
      if row_userid == UserId && row_albumid == id
        redirect('/response3')
      end
    end


    # Här kollar koden ifall användaren har råd att köpa albumet och samt "köper" albumet ifall pengarna räcker till
    # Albumet och UserId läggs till i user_album_rel ifall pengarna räcker till

    if price <= wallet
      db.execute("INSERT INTO user_album_rel (UserId, AlbumId) VALUES (?,?)",UserId, id)
      wallet -= price
      db.execute("UPDATE users SET Wallet = #{wallet} WHERE Userid = #{UserId}")
      session[:result]["Wallet"] = wallet
      redirect('/response1')
    else 
      redirect('/response2')
    end

    redirect('/store')
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
  
  
  