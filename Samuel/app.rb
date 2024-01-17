require 'slim'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'



get('/')  do
    slim(:start)
  end 
  
  get('/albums') do
    db = SQLite3::Database.new("db/chinook-crud.db")
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
    db = SQLite3::Database.new("db/chinook-crud.db")
    db.execute("INSERT INTO albums (Title, ArtistId) VALUES (?,?)",title, artist_id)
    redirect('/albums')
  end
  
  post('/albums/:id/delete') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/chinook-crud.db")
    db.execute("DELETE FROM albums WHERE AlbumId = ?",id)
    redirect('/albums')
  end
  
  post('/albums/:id/update') do
    id = params[:id].to_i
    title = params[:title]
    artist_id = params[:artistId].to_i
    db = SQLite3::Database.new("db/chinook-crud.db")
    db.execute("UPDATE albums SET Title=?,ArtistId=? WHERE AlbumId = ?",title,artist_id,id)
    redirect('/albums')
  end
  
  get('/albums/:id/edit') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/chinook-crud.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM albums WHERE AlbumId = ?",id).first
    slim(:"/albums/edit",locals:{result:result})
  end
  
  get('/albums/:id') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/chinook-crud.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM albums WHERE AlbumId = ?",id).first
    result2 = db.execute("SELECT Name FROM Artists WHERE ArtistId IN (SELECT ArtistId FROM Albums WHERE AlbumId = ?)",id).first
    p "Resultat2 är: #{result2}"
    slim(:"albums/show",locals:{result:result,result2:result2})
  end
  
  
  