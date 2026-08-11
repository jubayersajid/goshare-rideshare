import os
from flask import Flask, render_template, request, jsonify, session, redirect, url_for
import pymysql
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
app.secret_key = os.getenv('SECRET_KEY', 'goshare_super_secret_key')

# Aiven MySQL ডাটাবেজ কনফিগারেশন (আপনার ছবি অনুযায়ী আপডেট করা হয়েছে)
DB_CONFIG = {
    'host': 'goshare-ubayer-goshare.j.aivencloud.com',
    'user': 'avnadmin',
    'password': 'AVNS_x5ZAs_c_tFxX1_8zKHf',
    'database': 'defaultdb', # আপনার Aiven-এর ডিফল্ট ডাটাবেজ
    'port': 11375,
    'cursorclass': pymysql.cursors.DictCursor,
    'ssl': {'ssl': {}} # Aiven-এর SSL REQUIRED মেলাতে এটি আবশ্যক
}

def get_db():
    return pymysql.connect(**DB_CONFIG)

def get_fare_rate(vehicle_type):
    conn = get_db()
    cursor = conn.cursor()
    key = f"rate_{vehicle_type.lower()}"
    cursor.execute("SELECT SettingValue FROM Settings WHERE SettingKey = %s", (key,))
    res = cursor.fetchone()
    conn.close()
    if res:
        return float(res['SettingValue'])
    return 30 if vehicle_type == 'Car' else (15 if vehicle_type == 'Bike' else 20)

# ----------------- ROUTING & PAGES -----------------

@app.route('/')
def home():
    if 'user_id' in session:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login_page'))

@app.route('/login')
def login_page():
    return render_template('login.html')

@app.route('/register')
def register_page():
    return render_template('register.html')

@app.route('/dashboard')
def dashboard():
    if 'user_id' not in session:
        return redirect(url_for('login_page'))
    
    role = session.get('role')
    if role == 'Admin':
        return redirect(url_for('admin_dashboard'))
    elif role == 'Driver':
        return redirect(url_for('driver_dashboard'))

    user = {
        'id': session['user_id'],
        'name': session['name'],
        'email': session['email'],
        'role': session['role']
    }
    return render_template('dashboard.html', user=user)

@app.route('/driver-dashboard')
def driver_dashboard():
    if 'user_id' not in session:
        return redirect(url_for('login_page'))
    if session.get('role') != 'Driver':
        return redirect(url_for('dashboard'))
    
    driver = {
        'id': session['user_id'],
        'name': session['name'],
        'email': session['email'],
        'role': session['role']
    }
    return render_template('driver_dashboard.html', driver=driver)

@app.route('/admin-dashboard')
def admin_dashboard():
    if 'user_id' not in session:
        return redirect(url_for('login_page'))
    if session.get('role') != 'Admin':
        return redirect(url_for('dashboard'))
    
    admin = {
        'id': session['user_id'],
        'name': session['name'],
        'email': session['email'],
        'role': session['role']
    }
    return render_template('admin_dashboard.html', admin=admin)

# ----------------- AUTH APIS -----------------

@app.route('/api/login', methods=['POST'])
def login():
    try:
        data = request.get_json()
        email = data.get('email', '').strip()
        password = data.get('password', '').strip()

        conn = get_db()
        cursor = conn.cursor()
        
        cursor.execute("SELECT UserID, FullName, Email, Password, Role FROM Users WHERE Email = %s", (email,))
        user = cursor.fetchone()
        conn.close()

        if user:
            db_password = str(user['Password']).strip()
            is_valid = (db_password == password) or (
                db_password.startswith(('scrypt:', 'pbkdf2:')) and check_password_hash(db_password, password)
            )
            
            if is_valid:
                session['user_id'] = user['UserID']
                session['name'] = user['FullName']
                session['email'] = user['Email']
                session['role'] = user['Role']
                
                role_str = str(user['Role']).strip()
                if role_str == 'Admin':
                    redirect_url = '/admin-dashboard'
                elif role_str == 'Driver':
                    redirect_url = '/driver-dashboard'
                else:
                    redirect_url = '/dashboard'
                
                return jsonify({
                    'status': 'success', 
                    'message': f"স্বাগতম {user['FullName']}!", 
                    'redirect': redirect_url
                })
            else:
                return jsonify({'status': 'error', 'message': 'পাসওয়ার্ড ভুল হয়েছে!'})
        else:
            return jsonify({'status': 'error', 'message': 'এই ইমেইলে কোনো ইউজার পাওয়া যায়নি!'})
            
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})

@app.route('/api/register', methods=['POST'])
def register():
    try:
        data = request.get_json()
        name = data.get('name')
        email = data.get('email')
        phone = data.get('phone', '')
        password = data.get('password')
        role = data.get('role', 'Passenger')
        license_number = data.get('license_number', '')
        vehicle_type = data.get('vehicle_type', 'Car')

        if role == 'Admin':
            return jsonify({'status': 'error', 'message': 'পাবলিক রেজিস্ট্রেশন দিয়ে অ্যাডমিন অ্যাকাউন্ট খোলা সম্ভব নয়!'})

        if not name or not email or not password or not role:
            return jsonify({'status': 'error', 'message': 'সবগুলো ঘর সঠিকভাবে পূরণ করুন!'})

        if role == 'Driver' and not license_number:
            return jsonify({'status': 'error', 'message': 'ড্রাইভারের লাইসেন্স নম্বর প্রদান করা বাধ্যতামূলক!'})

        conn = get_db()
        cursor = conn.cursor()

        cursor.execute("SELECT UserID FROM Users WHERE Email = %s", (email,))
        if cursor.fetchone():
            conn.close()
            return jsonify({'status': 'error', 'message': 'এই ইমেইলটি দিয়ে ইতোমধ্যে অ্যাকাউন্ট খোলা হয়েছে!'})

        cursor.execute(
            "INSERT INTO Users (FullName, Email, Password, Phone, Role) VALUES (%s, %s, %s, %s, %s)",
            (name, email, password, phone, role)
        )
        user_id = cursor.lastrowid

        if role == 'Driver':
            cursor.execute(
                "INSERT INTO Drivers (UserID, LicenseNumber, VehicleType, AvailabilityStatus) VALUES (%s, %s, %s, 'Available')",
                (user_id, license_number, vehicle_type)
            )

        conn.commit()
        conn.close()
        return jsonify({'status': 'success', 'message': 'রেজিস্ট্রেশন সফল হয়েছে! এখন লগইন করুন।'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})

# ----------------- PASSENGER APIS -----------------

@app.route('/api/book-ride', methods=['POST'])
def book_ride():
    if 'user_id' not in session:
        return jsonify({'status': 'error', 'message': 'অনুগ্রহ করে লগইন করুন!'})
    
    try:
        data = request.get_json()
        passenger_id = session['user_id']
        pickup = data.get('pickup')
        dropoff = data.get('dropoff')
        distance = float(data.get('distance', 0))
        vehicle_type = data.get('vehicle_type', 'Car')

        rate = get_fare_rate(vehicle_type)
        fare = round(distance * rate)

        conn = get_db()
        cursor = conn.cursor()
        
        cursor.execute(
            "INSERT INTO Rides (PassengerID, PickupLocation, DropoffLocation, Distance, Fare, VehicleType, Status) VALUES (%s, %s, %s, %s, %s, %s, 'Requested')",
            (passenger_id, pickup, dropoff, distance, fare, vehicle_type)
        )

        conn.commit()
        conn.close()

        return jsonify({'status': 'success', 'message': 'রাইড বুকিং সফল হয়েছে!'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})

@app.route('/api/ride-history', methods=['GET'])
def ride_history():
    if 'user_id' not in session:
        return jsonify([])

    try:
        passenger_id = session['user_id']
        conn = get_db()
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT r.*, u.FullName as PartnerName, u.Phone as PartnerPhone
            FROM Rides r
            LEFT JOIN Drivers d ON r.DriverID = d.DriverID
            LEFT JOIN Users u ON d.UserID = u.UserID
            WHERE r.PassengerID = %s
            ORDER BY r.RideID DESC
        """, (passenger_id,))
        
        rides = cursor.fetchall()
        conn.close()

        history = []
        for r in rides:
            history.append({
                'ride_id': r.get('RideID'),
                'partner_name': r.get('PartnerName') if r.get('PartnerName') else 'Pending Driver',
                'partner_phone': r.get('PartnerPhone') if r.get('PartnerPhone') else '',
                'pickup': r.get('PickupLocation', ''),
                'dropoff': r.get('DropoffLocation', ''),
                'vehicle': r.get('VehicleType', 'Car'),
                'fare': float(r.get('Fare', 0)),
                'status': r.get('Status', 'Requested'),
                'date': str(r.get('CreatedAt', 'N/A'))
            })

        return jsonify(history)
    except Exception as e:
        return jsonify([])

# ----------------- DRIVER APIS -----------------

@app.route('/api/driver/available-rides', methods=['GET'])
def get_available_rides():
    if 'user_id' not in session or session.get('role') != 'Driver':
        return jsonify([])

    try:
        user_id = session['user_id']
        conn = get_db()
        cursor = conn.cursor()

        cursor.execute("SELECT DriverID FROM Drivers WHERE UserID = %s", (user_id,))
        driver_row = cursor.fetchone()
        
        if not driver_row:
            conn.close()
            return jsonify([])

        driver_id = driver_row['DriverID']
        
        cursor.execute("""
            SELECT r.*, u.FullName as PassengerName, u.Phone as PassengerPhone
            FROM Rides r
            JOIN Users u ON r.PassengerID = u.UserID
            WHERE (r.Status = 'Requested' AND (r.DriverID IS NULL OR r.DriverID = 0)) 
               OR (r.DriverID = %s AND r.Status IN ('Accepted', 'Completed'))
            ORDER BY r.RideID DESC
        """, (driver_id,))
        
        rides = cursor.fetchall()
        conn.close()

        results = []
        for r in rides:
            results.append({
                'ride_id': r.get('RideID'),
                'passenger_name': r.get('PassengerName'),
                'passenger_phone': r.get('PassengerPhone', 'N/A'),
                'pickup': r.get('PickupLocation'),
                'dropoff': r.get('DropoffLocation'),
                'distance': str(r.get('Distance', '0')),
                'vehicle': r.get('VehicleType', 'Car'),
                'fare': float(r.get('Fare', 0)),
                'status': r.get('Status'),
                'driver_id': r.get('DriverID'),
                'date': str(r.get('CreatedAt', 'N/A'))
            })

        return jsonify(results)
    except Exception as e:
        return jsonify([])

@app.route('/api/driver/update-ride', methods=['POST'])
def update_ride_status():
    if 'user_id' not in session or session.get('role') != 'Driver':
        return jsonify({'status': 'error', 'message': 'অনুমতি নেই!'})

    try:
        data = request.get_json()
        ride_id = data.get('ride_id')
        new_status = data.get('status')
        user_id = session['user_id']

        conn = get_db()
        cursor = conn.cursor()

        cursor.execute("SELECT DriverID FROM Drivers WHERE UserID = %s", (user_id,))
        driver_row = cursor.fetchone()

        if not driver_row:
            conn.close()
            return jsonify({'status': 'error', 'message': 'ড্রাইভারের প্রোফাইল ডাটাবেজে পাওয়া যায়নি!'})

        driver_id = driver_row['DriverID']

        if new_status == 'Accepted':
            cursor.execute(
                "UPDATE Rides SET Status = %s, DriverID = %s WHERE RideID = %s AND Status = 'Requested'",
                (new_status, driver_id, ride_id)
            )
        else:
            cursor.execute(
                "UPDATE Rides SET Status = %s WHERE RideID = %s AND DriverID = %s",
                (new_status, ride_id, driver_id)
            )

        conn.commit()
        conn.close()

        return jsonify({'status': 'success', 'message': f'রাইড সফলভাবে {new_status} করা হয়েছে!'})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})

# ----------------- ADMIN APIS -----------------

@app.route('/api/admin/users', methods=['GET'])
def get_all_users():
    if 'user_id' not in session or session.get('role') != 'Admin':
        return jsonify({'status': 'error', 'message': 'Unauthorized'})

    try:
        conn = get_db()
        cursor = conn.cursor()
        cursor.execute("SELECT UserID, FullName, Email, Phone, Role FROM Users ORDER BY UserID DESC")
        users = cursor.fetchall()
        conn.close()
        return jsonify({'status': 'success', 'users': users})
    except Exception as e:
        return jsonify({'status': 'error', 'message': str(e)})

@app.route('/api/admin/rates', methods=['GET', 'POST'])
def manage_rates():
    if 'user_id' not in session or session.get('role') != 'Admin':
        return jsonify({'status': 'error', 'message': 'Unauthorized'})

    conn = get_db()
    cursor = conn.cursor()

    if request.method == 'POST':
        try:
            data = request.get_json()
            car_rate = str(data.get('car', 30))
            bike_rate = str(data.get('bike', 15))
            cng_rate = str(data.get('cng', 20))

            cursor.execute("REPLACE INTO Settings (SettingKey, SettingValue) VALUES ('rate_car', %s), ('rate_bike', %s), ('rate_cng', %s)",
                           (car_rate, bike_rate, cng_rate))
            conn.commit()
            conn.close()
            return jsonify({'status': 'success', 'message': 'প্রতি কি.মি. ভাড়া সফলভাবে আপডেট হয়েছে!'})
        except Exception as e:
            conn.close()
            return jsonify({'status': 'error', 'message': str(e)})
    else:
        cursor.execute("SELECT * FROM Settings WHERE SettingKey LIKE 'rate_%'")
        settings = cursor.fetchall()
        conn.close()

        rates = {'car': 30, 'bike': 15, 'cng': 20}
        for s in settings:
            if s['SettingKey'] == 'rate_car': rates['car'] = float(s['SettingValue'])
            if s['SettingKey'] == 'rate_bike': rates['bike'] = float(s['SettingValue'])
            if s['SettingKey'] == 'rate_cng': rates['cng'] = float(s['SettingValue'])

        return jsonify({'status': 'success', 'rates': rates})

@app.route('/api/logout')
def logout():
    session.clear()
    return redirect(url_for('login_page'))

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    app.run(host='0.0.0.0', port=port, debug=False)
