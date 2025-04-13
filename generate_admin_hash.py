from flask_bcrypt import Bcrypt

bcrypt = Bcrypt()
hashed = bcrypt.generate_password_hash("yourpassword").decode()
print(bcrypt.generate_password_hash("newadmin123").decode())

#password: newadmin123
#hash: $2b$12$rp3BrhGP0eXZVm90Zc2q9uBzIyPfsxF8PrGBreGH8ZQ/4zzneUKBC



#$2b$12$SGy.tDnGkkl05ySyJ5colufAIhLYZVjS/pzGHM1IwX0C2Lq5NZDue

#INSERT INTO admins (firstname, lastname, email, password)
#VALUES ('Admin', 'User', 'admin@uj.ac.za', '$2b$12$SGy.tDnGkkl05ySyJ5colufAIhLYZVjS/pzGHM1IwX0C2Lq5NZDue');

