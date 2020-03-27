require 'mysql2'

class Formatter # :nodoc:
  UNKNOWN = ['unknown', 'none given', 'N/A'].freeze
  ABBREVIATIONS = { 'Twp' => 'Township', 'Hwy' => 'Highway' }.freeze

  def initialize
    @client = Mysql2::Client.new(host: '', username: '', password: '', database: '')
  end

  def run
    rows.each do |row|
      @str = row["candidate_office_name"]
      next if @str.length.zero? || UNKNOWN.include?(@str)

      clean_name = prepare_clean_name
      sentence = "The candidate is running for the #{clean_name} office."
      insert(row['id'], clean_name, sentence)
    end
  end

  private

  def rows
    @client.query("SELECT id, candidate_office_name FROM hle_dev_test_eldar_mustafaiev;")
  end

  def prepare_clean_name
    ABBREVIATIONS.each { |k, v| @str.gsub!(k, v) }
    strings = @str.split(/\//)
                  .reject { |e| e.to_s.empty? }
                  .map { |str| str[-1] == '.' ? str.delete('.') : str }
                  .map { |str| str.include?(',') ? replace_comma_with_parentheses(str) : str }

    reorder(strings)
    capitalize_text_in_parentheses if @str.include?('(')
    delete_duplicates
  end

  def reorder(strings)
    if strings.length > 1
      @str = ''
      strings = strings.unshift(strings.pop)
      strings.each_with_index do |el, i|
        @str += case i
                when 0
                  el
                when 1
                  " #{el.downcase}"
                else
                  " and #{el.downcase}"
                end
      end
    else
      @str = strings[0].downcase
    end
  end

  def capitalize_text_in_parentheses
    strings = @str.split('(')
    capitalized = strings[1].split(' ').map(&:capitalize).join(' ')
    @str = strings.shift(1).push(capitalized).join('(')
  end

  def delete_duplicates
    @str = @str.split.uniq(&:downcase).join(' ')
  end

  def replace_comma_with_parentheses(string)
    str = string.split(',')
    return str[0] if str.length == 1

    "#{str[0].downcase} (#{str[1].split.join(' ')})"
  end

  def insert(id, clean_name, sentence)
    @client.query("UPDATE hle_dev_test_eldar_mustafaiev SET clean_name = \"#{clean_name}\", sentence = \"#{sentence}\" WHERE id = \"#{id}\";")
  end
end

Formatter.new.run


