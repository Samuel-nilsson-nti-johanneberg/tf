require 'sqlite3'
require 'bcrypt'

def connect_to_db
    SQLite3::Database.new("db/musicsite.db")
end

def save_wallet(session_result)
    wallet = session_result["Wallet"]
    userid = session_result["Userid"]
    db = connect_to_db
    db.execute("UPDATE users SET Wallet = ? WHERE Userid = ?", wallet, userid)
end

def check_username(username)
    db = connect_to_db
    results = db.execute("SELECT Username FROM users")
    results.each do |current_username|
        return false if username == current_username[0]
    end
    true
end

def check_email(email)
    db = connect_to_db
    results = db.execute("SELECT Email FROM users")
    results.each do |current_email|
        return false if email == current_email[0]
    end
    true
end

def register_user(username, password, firstname, lastname, email)
    db = connect_to_db
    password_digest = BCrypt::Password.create(password)
    db.execute("INSERT INTO users (Username, Pwdigest, Firstname, Lastname, Email) VALUES (?,?,?,?,?)",username,password_digest,firstname,lastname,email)
end

def login(username)
    db = connect_to_db
    db.results_as_hash = true
    db.execute("SELECT * FROM users WHERE username = ?", username).first
end

def purchase_album(id, session_result)
    db = connect_to_db
    user_id = session_result["Userid"]
    wallet = session_result["Wallet"]
    price = db.execute("SELECT * FROM albums WHERE AlbumId = ?",id).first[3].to_i

    results = db.execute("SELECT * FROM user_album_rel")
    results.each do |row|
        row_userid = row[0] 
        row_albumid = row[1]
        if row_userid == user_id && row_albumid == id
            return "response3"
        end
    end

    if price <= wallet
        db.execute("INSERT INTO user_album_rel (UserId, AlbumId) VALUES (?,?)", user_id, id)
        wallet -= price
        db.execute("UPDATE users SET Wallet = ? WHERE Userid = ?", wallet, user_id)
        session_result["Wallet"] = wallet
        return "response1"
    else
        return "response2"
    end
end

def refund_album(id, session_result)
    db = connect_to_db
    price = db.execute("SELECT * FROM albums WHERE AlbumId = ?",id).first[3].to_i
    price = (price/2).to_i
    user_id = session_result["Userid"]

    db.execute("DELETE FROM user_album_rel WHERE AlbumId = ? AND UserId = ?",id,user_id)
    session_result["Wallet"] += price
    save_wallet(session_result)
end
