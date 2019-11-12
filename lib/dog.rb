require 'pry'

class Dog
  attr_reader :name, :breed, :id
  attr_writer :name, :breed, :id

  def initialize(name:, breed:, id: nil)
      @name = name
      @breed = breed
  end

  def self.create_table
      sql = <<-SQL
          CREATE TABLE IF NOT EXISTS dogs (
              id INTEGER PRIMARY KEY,
              name TEXT,
              breed TEXT
          )
      SQL
      DB[:conn].execute(sql)
  end

  def self.drop_table
    DB[:conn].execute("DROP TABLE dogs")
  end

  def save
      sql = <<-SQL
          INSERT INTO dogs (name, breed)
          VALUES (?, ?)
      SQL
      DB[:conn].execute(sql, self.name, self.breed)
      @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs")[0][0]
      self
  end

  def self.create(attributes)
    dog = Dog.new(name: attributes[:name], breed: attributes[:breed], id: nil)
    dog.save
    dog
  end

  def self.new_from_db(row)
    dog = Dog.new(name: row[1], breed: row[2], id: nil)
    dog.id = row[0]
    dog
  end

  def self.find_by_id(id)
    sql = <<-SQL
     SELECT *
     FROM dogs
     WHERE id = ?
   SQL

   DB[:conn].execute(sql, id).map do |row|
     self.new_from_db(row)
   end.first
  end

  def self.find_or_create_by(name:, breed:)
    dog = DB[:conn].execute("SELECT * FROM dogs WHERE name = ? AND breed = ?", name, breed)
    if !dog.empty?
      dog_row = dog[0]
      new_dog = Dog.new_from_db(dog_row)
    else
      new_dog = self.create(name: name, breed: breed)
    end
    new_dog
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM dogs WHERE name = ?"
    dog = DB[:conn].execute(sql, name)[0]
    # Dog.new(result[1], result[2], result[0])
    Dog.new_from_db(dog)
  end

  def update
    sql = "UPDATE dogs SET name = ?, breed = ? WHERE id = ?"
    DB[:conn].execute(sql, self.name, self.breed, self.id)
  end
end
