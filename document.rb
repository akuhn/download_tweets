require %{json}
require %{sqlite3}


class Document

  def initialize(fname, table_name)
    raise if /[^a-z]/ === table_name

    @table_name = table_name
    @database = SQLite3::Database.new(fname)

    @database.execute %{
      CREATE TABLE IF NOT EXISTS `#@table_name` (
        `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
        `key` VARCHAR(512),
        `value` TEXT
      )
    }
  end

  def get(document_id)
    rows = @database.execute %{
      SELECT value FROM `#@table_name`
      WHERE key = ? ORDER BY created_at
    }, document_id

    return rows.any? ? (JSON.parse rows.last.first) : nil
  end

  def update(document_id, value)
    raise unless Hash === value

    @database.execute %{
      INSERT INTO `#@table_name` (`key`, `value`)
      VALUES (?, ?)
    }, [document_id, value.to_json]
    return value
  end

  def fetch(document_id)
    raise unless block_given?

    value = self[document_id]
    return value ? value : self[document_id] = yield
  end

  # def delete_all_cache_entries
  #   @db.execute %{DELETE FROM `cache`}
  # end

  # def delete_cache_entry(key)
  #   @db.execute %{DELETE FROM `cache` WHERE `key` = ?}, key
  # end

  def [](query)
    @database.execute(query)
  end
end
