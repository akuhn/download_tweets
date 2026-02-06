require 'sqlite3'

class Cache

  def initialize(fname)
    @db = SQLite3::Database.new(fname)
    @db.execute %{
      CREATE TABLE IF NOT EXISTS `cache` (
        `key` VARCHAR(1024),
        `value` TEXT,
        UNIQUE (`key`) ON CONFLICT REPLACE
      )
    }
  end

  def fetch(key)
    rows = @db.execute %{SELECT `value` FROM `cache` WHERE `key` = ?}, key
    return rows.first.first if rows.first

    value = yield
    @db.execute %{INSERT INTO `cache` (`key`, `value`) VALUES (?, ?)}, [key, value]
    return value
  end

  def delete_all_cache_entries
    @db.execute %{DELETE FROM `cache`}
  end

  def delete_cache_entry(key)
    @db.execute %{DELETE FROM `cache` WHERE `key` = ?}, key
  end

  def [](query)
    @db.execute(query)
  end
end
