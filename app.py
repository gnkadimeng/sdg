from flask import Flask, render_template, request, redirect, url_for, session, flash, send_file
from flask_bcrypt import Bcrypt
import psycopg2
from psycopg2.extras import RealDictCursor
import os
import json
import pandas as pd
from io import BytesIO
from config import get_db_connection, SECRET_KEY

app = Flask(__name__)
app.secret_key = SECRET_KEY
bcrypt = Bcrypt(app)

# Database connection

conn = get_db_connection()
if conn:
    print("Database connected successfully")
    conn.close()
else:
    print("Database connection failed")

@app.route('/')
def landing():
    return render_template('home.html')

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        firstname = request.form['firstName']
        lastname = request.form['lastName']
        email = request.form['email']
        password = request.form['password']
        confirmpassword = request.form['confirmPassword']

        if password != confirmpassword:
            flash("Passwords do not match.", "danger")
            return render_template('register.html')

        hashed_password = bcrypt.generate_password_hash(password).decode('utf-8')

        try:
            conn = get_db_connection()
            cur = conn.cursor()
            cur.execute("INSERT INTO users (firstname, lastname, email, password) VALUES (%s, %s, %s, %s)",
                        (firstname, lastname, email, hashed_password))
            conn.commit()
            cur.close()
            conn.close()
            flash("Registration successful. Please log in.", "success")
            return redirect(url_for('login'))
        except Exception as e:
            flash(f"Registration error: {e}", "danger")
            return render_template('register.html')

    return render_template('register.html')

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']

        try:
            conn = get_db_connection()
            cur = conn.cursor(cursor_factory=RealDictCursor)
            cur.execute("SELECT * FROM users WHERE email = %s", (email,))
            user = cur.fetchone()
            cur.close()
            conn.close()

            if user and bcrypt.check_password_hash(user['password'], password):
                session['user_id'] = user['id']
                session['user_name'] = user['firstname']
                session['is_admin'] = False
                flash("Login successful!", "success")
                return redirect(url_for('questionnaire'))
            else:
                flash("Invalid email or password.", "danger")
        except Exception as e:
            flash(f"Login error: {e}", "danger")

    return render_template('login.html')

@app.route('/admin/login', methods=['GET', 'POST'])
def admin_login():
    if request.method == 'POST':
        email = request.form['email']
        password = request.form['password']

        try:
            conn = get_db_connection()
            cur = conn.cursor(cursor_factory=RealDictCursor)
            cur.execute("SELECT * FROM admins WHERE email = %s", (email,))
            admin = cur.fetchone()
            cur.close()
            conn.close()

            if admin and bcrypt.check_password_hash(admin['password'], password):
                session['user_id'] = admin['id']
                session['user_name'] = admin['firstname']
                session['is_admin'] = True
                flash("Welcome, Admin!", "success")
                return redirect(url_for('admin_dashboard'))
            else:
                flash("Invalid admin credentials.", "danger")
        except Exception as e:
            flash(f"Admin login error: {e}", "danger")

    return render_template('admin_login.html')

@app.route('/admin/dashboard')
def admin_dashboard():
    if not session.get('is_admin'):
        flash("Admin access only.", "danger")
        return redirect(url_for('login'))
    return render_template('admin_dashboard.html', admin=session['user_name'])

@app.route('/admin/questionnaires')
def admin_questionnaires():
    if not session.get('is_admin'):
        flash("Admin access only.", "danger")
        return redirect(url_for('login'))

    faculty_filter = request.args.get('faculty')
    year_filter = request.args.get('year')

    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)

        # Build the query dynamically based on filters
        query = """
            SELECT qr.id, u.firstname, u.lastname, u.email, qr.faculty, qr.year, qr.preference, qr.submitted_at
            FROM questionnaire_responses qr
            JOIN users u ON qr.user_id = u.id
        """
        filters = []
        values = []

        if faculty_filter:
            filters.append("qr.faculty = %s")
            values.append(faculty_filter)

        if year_filter:
            filters.append("qr.year = %s")
            values.append(year_filter)

        if filters:
            query += " WHERE " + " AND ".join(filters)

        query += " ORDER BY qr.submitted_at DESC"

        cur.execute(query, tuple(values))
        responses = cur.fetchall()

        # Get distinct faculties and years for filter dropdowns
        cur.execute("SELECT DISTINCT faculty FROM questionnaire_responses ORDER BY faculty")
        faculties = [row['faculty'] for row in cur.fetchall()]

        cur.execute("SELECT DISTINCT year FROM questionnaire_responses ORDER BY year")
        years = [row['year'] for row in cur.fetchall()]

        cur.close()
        conn.close()

    except Exception as e:
        flash(f"Could not retrieve questionnaire responses: {e}", "danger")
        responses = []
        faculties = []
        years = []

    return render_template('admin_questionnaires.html', responses=responses, faculties=faculties, years=years, selected_faculty=faculty_filter, selected_year=year_filter)


@app.route('/admin/questionnaires/export')
def export_questionnaires():
    if not session.get('is_admin'):
        flash("Admin access only.", "danger")
        return redirect(url_for('login'))

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            SELECT u.firstname, u.lastname, u.email, qr.faculty, qr.year, qr.preference, qr.submitted_at
            FROM questionnaire_responses qr
            JOIN users u ON qr.user_id = u.id
            ORDER BY qr.submitted_at DESC
        """)
        data = cur.fetchall()
        columns = [desc[0] for desc in cur.description]
        cur.close()
        conn.close()

        df = pd.DataFrame(data, columns=columns)
        output = BytesIO()
        with pd.ExcelWriter(output, engine='xlsxwriter') as writer:
            df.to_excel(writer, index=False, sheet_name='Responses')

        output.seek(0)
        return send_file(output, as_attachment=True, download_name="questionnaire_responses.xlsx", mimetype="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
    except Exception as e:
        flash(f"Export failed: {e}", "danger")
        return redirect(url_for('admin_questionnaires'))

@app.route('/admin/users')
def admin_users():
    if not session.get('is_admin'):
        flash("Admin access only.", "danger")
        return redirect(url_for('login'))

    try:
        conn = get_db_connection()
        cur = conn.cursor(cursor_factory=RealDictCursor)
        cur.execute("SELECT id, firstname, lastname, email, active FROM users ORDER BY id DESC")
        users = cur.fetchall()
        cur.close()
        conn.close()
    except Exception as e:
        flash(f"Failed to load users: {e}", "danger")
        users = []

    return render_template('admin_users.html', users=users)

@app.route('/admin/users/<int:user_id>/toggle')
def toggle_user_status(user_id):
    if not session.get('is_admin'):
        flash("Admin access only.", "danger")
        return redirect(url_for('login'))

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("UPDATE users SET active = NOT active WHERE id = %s", (user_id,))
        conn.commit()
        cur.close()
        conn.close()
        flash("User status updated successfully.", "success")
    except Exception as e:
        flash(f"Failed to update user status: {e}", "danger")

    return redirect(url_for('admin_users'))

@app.route('/admin/users/<int:user_id>/reset')
def reset_user_password(user_id):
    if not session.get('is_admin'):
        flash("Admin access only.", "danger")
        return redirect(url_for('login'))

    try:
        temp_password = 'UJstudent2024'
        hashed_password = bcrypt.generate_password_hash(temp_password).decode('utf-8')

        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("UPDATE users SET password = %s WHERE id = %s", (hashed_password, user_id))
        conn.commit()
        cur.close()
        conn.close()

        flash("User password has been reset to 'UJstudent2024'.", "info")
    except Exception as e:
        flash(f"Failed to reset password: {e}", "danger")

    return redirect(url_for('admin_users'))


@app.route('/dashboard')
def dashboard():
    if 'user_id' not in session:
        flash("Please log in first.", "warning")
        return redirect(url_for('login'))
    return render_template('dashboard.html', user=session['user_name'])


@app.route('/questionnaire', methods=['GET', 'POST'])
def questionnaire():
    if 'user_id' not in session:
        flash("Please log in to continue.", "warning")
        return redirect(url_for('login'))

    user_id = session['user_id']

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("SELECT id FROM questionnaire_responses WHERE user_id = %s", (user_id,))
        existing = cur.fetchone()

        if existing:
            return redirect(url_for('dashboard'))

        if request.method == 'POST':
            faculty = request.form['faculty']
            year = request.form['year']
            preference = request.form['preference']

            cur.execute("""
                INSERT INTO questionnaire_responses (user_id, faculty, year, preference)
                VALUES (%s, %s, %s, %s)
            """, (user_id, faculty, year, preference))
            conn.commit()
            flash("Thank you for completing the questionnaire!", "success")
            return redirect(url_for('dashboard'))

        cur.close()
        conn.close()

    except Exception as e:
        flash(f"Error loading questionnaire: {e}", "danger")

    return render_template('questionnaire.html')


@app.route('/learn/<int:sdg_id>')
def learn_sdg(sdg_id):
    if 'user_id' in session:
        try:
            conn = get_db_connection()
            cur = conn.cursor()
            cur.execute("INSERT INTO sdg_activity (user_id, sdg_id, action) VALUES (%s, %s, 'view')",
                        (session['user_id'], sdg_id))
            conn.commit()
            cur.close()
            conn.close()
        except Exception as e:
            print(f"Activity log error (view): {e}")

    return render_template('learn.html', sdg_id=sdg_id)

@app.route('/sdg/<int:sdg_num>', methods=['GET', 'POST'])
def sdg_quiz(sdg_num):
    riddle_path = os.path.join('riddles', f'sdg{sdg_num}.json')
    if not os.path.exists(riddle_path):
        flash("Riddle file not found.", "danger")
        return redirect(url_for('dashboard'))

    with open(riddle_path, 'r') as file:
        riddles = json.load(file)

    if session.get('sdg_num') != sdg_num:
        session['riddle_index'] = 0
        session['clues_used'] = 0
        session['sdg_num'] = sdg_num

        if 'user_id' in session:
            try:
                conn = get_db_connection()
                cur = conn.cursor()
                cur.execute("INSERT INTO sdg_activity (user_id, sdg_id, action) VALUES (%s, %s, 'play')",
                            (session['user_id'], sdg_num))
                conn.commit()
                cur.close()
                conn.close()
            except Exception as e:
                print(f"Activity log error (play): {e}")

    index = session['riddle_index']

    if index >= len(riddles):
        # Pass all riddles to the template to show answers
        return render_template('completed.html', 
                             sdg_num=sdg_num, 
                             clues=session['clues_used'],
                             riddles=riddles)

    riddle = riddles[index]
    message = ''
    clue = ''

    if request.method == 'POST':
        answer = request.form.get('answer', '').strip().lower()
        if answer == riddle['answer'].lower():
            session['riddle_index'] += 1
            return redirect(url_for('sdg_quiz', sdg_num=sdg_num))
        else:
            message = '❌ Incorrect. Try again.'
            if 'show_clue' in request.form:
                clue = riddle.get('clue', '')
                session['clues_used'] += 1

    return render_template('riddle.html', riddle=riddle, index=index + 1, clue=clue, message=message, sdg_num=sdg_num)

@app.route('/admin/sdg-stats')
def admin_sdg_stats():
    if not session.get('is_admin'):
        flash("Admin access only.", "danger")
        return redirect(url_for('login'))

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            SELECT sdg_id,
                   COUNT(*) FILTER (WHERE action = 'view') AS views,
                   COUNT(*) FILTER (WHERE action = 'play') AS plays
            FROM sdg_activity
            GROUP BY sdg_id
            ORDER BY sdg_id
        """)
        stats = cur.fetchall()
        cur.close()
        conn.close()
    except Exception as e:
        flash(f"Failed to load SDG stats: {e}", "danger")
        stats = []

    return render_template('admin_sdg_stats.html', stats=stats)

@app.route('/admin/sdg-charts')
def admin_sdg_charts():
    if not session.get('is_admin'):
        flash("Admin access only.", "danger")
        return redirect(url_for('login'))

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            SELECT sdg_id,
                   COUNT(*) FILTER (WHERE action = 'view') AS views,
                   COUNT(*) FILTER (WHERE action = 'play') AS plays
            FROM sdg_activity
            GROUP BY sdg_id
            ORDER BY sdg_id
        """)
        rows = cur.fetchall()
        cur.close()
        conn.close()

        labels = [f"SDG {row[0]}" for row in rows]
        views = [row[1] for row in rows]
        plays = [row[2] for row in rows]

    except Exception as e:
        flash(f"Failed to load chart data: {e}", "danger")
        labels, views, plays = [], [], []

    return render_template('admin_sdg_charts.html', labels=labels, views=views, plays=plays)

@app.route('/profile')
def profile():
    if 'user_id' not in session:
        flash("Please log in to view your profile.", "warning")
        return redirect(url_for('login'))

    user_id = session['user_id']
    user_name = session['user_name']

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("""
            SELECT sdg_id, action, COUNT(*) 
            FROM sdg_activity 
            WHERE user_id = %s 
            GROUP BY sdg_id, action 
            ORDER BY sdg_id
        """, (user_id,))
        data = cur.fetchall()
        cur.close()
        conn.close()

        engagement = {}
        total_points = 0

        for row in data:
            sdg_id, action, count = row
            if sdg_id not in engagement:
                engagement[sdg_id] = {'view': 0, 'play': 0}
            engagement[sdg_id][action] = count

            if action == 'view':
                total_points += 10 * count
            elif action == 'play':
                total_points += 20 * count

    except Exception as e:
        flash(f"Could not load your profile data: {e}", "danger")
        engagement = {}
        total_points = 0

    return render_template('profile.html', name=user_name, engagement=engagement, points=total_points)



@app.route('/logout')
def logout():
    session.clear()
    flash("You have been logged out.", "info")
    return redirect(url_for('login'))


if __name__ == '__main__':
    app.run(debug=True)
