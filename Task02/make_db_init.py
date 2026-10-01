import csv
import os

DATA_DIR = os.path.dirname(os.path.abspath(__file__))

def escape_sql(value):
    if value is None or value == '':
        return 'NULL'
    return "'" + str(value).replace("'", "''") + "'"

def generate_sql():
    sql_lines = []
    
    sql_lines.append("-- Удаление старых таблиц")
    sql_lines.append("DROP TABLE IF EXISTS movies;")
    sql_lines.append("DROP TABLE IF EXISTS ratings;")
    sql_lines.append("DROP TABLE IF EXISTS tags;")
    sql_lines.append("DROP TABLE IF EXISTS users;")
    sql_lines.append("")
    
    sql_lines.append("-- Создание таблицы movies")
    sql_lines.append("CREATE TABLE movies (")
    sql_lines.append("    id INTEGER PRIMARY KEY,")
    sql_lines.append("    title TEXT,")
    sql_lines.append("    year TEXT,")
    sql_lines.append("    genres TEXT")
    sql_lines.append(");")
    sql_lines.append("")
    
    sql_lines.append("-- Создание таблицы ratings")
    sql_lines.append("CREATE TABLE ratings (")
    sql_lines.append("    id INTEGER PRIMARY KEY,")
    sql_lines.append("    user_id INTEGER,")
    sql_lines.append("    movie_id INTEGER,")
    sql_lines.append("    rating REAL,")
    sql_lines.append("    timestamp INTEGER")
    sql_lines.append(");")
    sql_lines.append("")
    
    sql_lines.append("-- Создание таблицы tags")
    sql_lines.append("CREATE TABLE tags (")
    sql_lines.append("    id INTEGER PRIMARY KEY,")
    sql_lines.append("    user_id INTEGER,")
    sql_lines.append("    movie_id INTEGER,")
    sql_lines.append("    tag TEXT,")
    sql_lines.append("    timestamp INTEGER")
    sql_lines.append(");")
    sql_lines.append("")
    
    sql_lines.append("-- Создание таблицы users")
    sql_lines.append("CREATE TABLE users (")
    sql_lines.append("    id INTEGER PRIMARY KEY,")
    sql_lines.append("    name TEXT,")
    sql_lines.append("    email TEXT,")
    sql_lines.append("    gender TEXT,")
    sql_lines.append("    register_date TEXT,")
    sql_lines.append("    occupation TEXT")
    sql_lines.append(");")
    sql_lines.append("")
    
    sql_lines.append("BEGIN TRANSACTION;")
    sql_lines.append("")
    
    # movies.csv
    sql_lines.append("-- Загрузка данных в movies")
    filepath = os.path.join(DATA_DIR, 'movies.csv')
    with open(filepath, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        next(reader)
        for row in reader:
            if len(row) >= 3:
                movie_id = row[0]
                title_year = row[1]
                genres = row[2]
                year = 'NULL'
                title = title_year
                if '(' in title_year and ')' in title_year:
                    start = title_year.rfind('(')
                    end = title_year.rfind(')')
                    year = title_year[start+1:end]
                    title = title_year[:start].strip()
                sql_lines.append("INSERT INTO movies VALUES (" + movie_id + ", " + escape_sql(title) + ", " + escape_sql(year) + ", " + escape_sql(genres) + ");")
    sql_lines.append("")
    
    # ratings.csv
    sql_lines.append("-- Загрузка данных в ratings")
    filepath = os.path.join(DATA_DIR, 'ratings.csv')
    row_id = 1
    with open(filepath, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        next(reader)
        for row in reader:
            if len(row) >= 4:
                user_id, movie_id, rating, timestamp = row[0], row[1], row[2], row[3]
                sql_lines.append("INSERT INTO ratings VALUES (" + str(row_id) + ", " + user_id + ", " + movie_id + ", " + rating + ", " + timestamp + ");")
                row_id += 1
    sql_lines.append("")
    
    # tags.csv
    sql_lines.append("-- Загрузка данных в tags")
    filepath = os.path.join(DATA_DIR, 'tags.csv')
    row_id = 1
    with open(filepath, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        next(reader)
        for row in reader:
            if len(row) >= 4:
                user_id, movie_id, tag, timestamp = row[0], row[1], row[2], row[3]
                sql_lines.append("INSERT INTO tags VALUES (" + str(row_id) + ", " + user_id + ", " + movie_id + ", " + escape_sql(tag) + ", " + timestamp + ");")
                row_id += 1
    sql_lines.append("")
    
    # users.txt - ИСПРАВЛЕНО: берем поля с индекса 1, т.к. поле 0 - это ID из файла
    sql_lines.append("-- Загрузка данных в users")
    filepath = os.path.join(DATA_DIR, 'users.txt')
    row_id = 1
    with open(filepath, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = line.split('|')
            if len(parts) >= 6:
                # parts[0] - ID из файла (пропускаем)
                # parts[1] - name, parts[2] - email, parts[3] - gender, parts[4] - register_date, parts[5] - occupation
                name, email, gender, register_date, occupation = parts[1], parts[2], parts[3], parts[4], parts[5]
                sql_lines.append("INSERT INTO users VALUES (" + str(row_id) + ", " + escape_sql(name) + ", " + escape_sql(email) + ", " + escape_sql(gender) + ", " + escape_sql(register_date) + ", " + escape_sql(occupation) + ");")
                row_id += 1
    
    sql_lines.append("")
    sql_lines.append("COMMIT;")
    
    return '\n'.join(sql_lines)

sql_script = generate_sql()
output_file = os.path.join(DATA_DIR, 'db_init.sql')
with open(output_file, 'w', encoding='utf-8') as f:
    f.write(sql_script)
print(f"SQL-скрипт создан: {output_file}")
