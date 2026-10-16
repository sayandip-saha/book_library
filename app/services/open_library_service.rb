require "net/http"
require "json"
require "uri"

class OpenLibraryService
  BASE_URL = "https://openlibrary.org/api/books"

  CANONICAL_GENRES = {
    "Dystopian" => [
      "dystop", "totalitarian", "authoritarian", "1984", "orwellian", "post-apocalyptic"
    ],
    "Fantasy" => [
      "magic", "wizard", "witches", "dragon", "mythology", "sorcery", "epic fantasy", "hogwarts", "fantasy fiction", "fantasy"
    ],
    "Science Fiction" => [
      "space opera", "time travel", "cyberpunk", "extraterrestrial", "space flight", "alien", "science fiction", "scifi", "sci-fi"
    ],
    "Mystery & Thriller" => [
      "thriller", "suspense", "mystery", "detective", "crime", "espionage", "investigation", "murder", "puzzles"
    ],
    "Classics" => [
      "classic literature", "fiction classics", "classics", "classic", "literary classics"
    ],
    "Historical Fiction" => [
      "historical fiction", "regency", "victorian", "world war", "civil war", "middle ages", "gothic"
    ],
    "Romance" => [
      "romance", "courtship", "love stories", "regency romance", "romantic fiction"
    ],
    "Computer Science & Tech" => [
      "computer", "software", "programming", "coding", "agile", "web development", "data science", "algorithm", "artificial intelligence"
    ],
    "Philosophy" => [
      "philosophy", "philosophical", "ethics", "existentialism", "epistemology", "metaphysics", "logic"
    ],
    "Biography & Memoir" => [
      "biography", "autobiography", "memoir", "diaries", "personal narratives"
    ],
    "History" => [
      "history", "historical", "civilization", "ancient", "modern history"
    ],
    "Politics & Society" => [
      "political science", "politics", "sociology", "social sciences", "social conditions", "civil rights", "race relations"
    ],
    "Business & Economics" => [
      "business", "economics", "management", "entrepreneurship", "finance", "investing"
    ],
    "Psychology" => [
      "psychology", "mental health", "psychoanalysis", "cognitive"
    ],
    "Science & Nature" => [
      "physics", "chemistry", "biology", "astronomy", "nature", "evolution", "ecology"
    ],
    "Poetry & Drama" => [
      "poetry", "poems", "drama", "plays", "theater"
    ],
    "Young Adult & Children" => [
      "young adult", "ya", "juvenile fiction", "teen", "children", "juvenile", "coming of age"
    ],
    "Horror" => [
      "horror", "supernatural", "vampire", "ghost stories"
    ],
    "Self-Help" => [
      "self-help", "personal development", "motivational", "mindfulness"
    ],
    "Literary Fiction" => [
      "literary fiction", "contemporary fiction", "modern fiction", "fiction", "novel"
    ]
  }.freeze

  def self.fetch_by_isbn(isbn, create_associations: true, create_book: false)
    clean_isbn = isbn.to_s.gsub(/[^0-9X]/i, "")
    return { success: false, error: "Please provide a valid ISBN." } if clean_isbn.empty?

    url = URI("#{BASE_URL}?bibkeys=ISBN:#{clean_isbn}&format=json&jscmd=data")

    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = (url.scheme == "https")
    http.open_timeout = 8
    http.read_timeout = 8

    request = Net::HTTP::Get.new(url)
    request["User-Agent"] = "BookLibraryApp/1.0 (sayandip-saha)"

    response = http.request(request)

    return { success: false, error: "Open Library returned HTTP #{response.code}" } unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    book_data = data["ISBN:#{clean_isbn}"]

    if book_data.nil? || book_data.empty?
      return fallback_lookup(clean_isbn, create_associations, create_book)
    end

    parse_book_data(clean_isbn, book_data, create_associations, create_book)
  rescue JSON::ParserError
    { success: false, error: "Failed to parse data from Open Library." }
  rescue StandardError => e
    { success: false, error: "Unable to connect to Open Library: #{e.message}" }
  end

  private

  def self.parse_book_data(clean_isbn, book_data, create_associations, create_book)
    title = book_data["title"]
    authors = book_data["authors"] || []
    author_name = authors.first&.dig("name")&.strip

    # Extract 4-digit publication year
    pub_date = book_data["publish_date"].to_s
    year_match = pub_date.match(/\b(1\d{3}|20\d{2})\b/)
    publication_year = year_match ? year_match[0].to_i : nil

    # Extract best cover URL
    cover_image_url = book_data.dig("cover", "large") ||
                      book_data.dig("cover", "medium") ||
                      book_data.dig("cover", "small") ||
                      "https://covers.openlibrary.org/b/isbn/#{clean_isbn}-L.jpg"

    # Extract description / excerpts / notes
    description = ""
    if book_data["excerpts"].is_a?(Array) && book_data["excerpts"].any?
      description = book_data["excerpts"].first["text"].to_s.strip
    elsif book_data["notes"].to_s.strip.length > 0
      description = book_data["notes"].to_s.strip
    elsif book_data["subtitle"].to_s.strip.length > 0
      description = book_data["subtitle"].to_s.strip
    end

    # Extract all subjects and genres to accurately determine real category
    all_subjects = []
    all_subjects.concat(book_data["subjects"].map { |s| s["name"] }) if book_data["subjects"].is_a?(Array)
    all_subjects.concat(book_data["genres"].map { |g| g["name"] }) if book_data["genres"].is_a?(Array)
    all_subjects.concat(book_data["subject_places"].map { |p| p["name"] }) if book_data["subject_places"].is_a?(Array)

    category_name = determine_category(all_subjects)

    # Persist or find Author in Database
    author = find_or_create_author(author_name, persist: create_associations)

    # Persist or find Category in Database
    category = find_or_create_category(category_name, persist: create_associations)

    # Optionally persist or find Book in Database
    book = nil
    if create_book
      book = find_or_create_book(clean_isbn, title, author, category, publication_year, description, cover_image_url)
    end

    {
      success: true,
      isbn: clean_isbn,
      title: title,
      author_name: author&.name || author_name,
      author_id: author&.id,
      category_name: category&.name || category_name,
      category_id: category&.id,
      publication_year: publication_year,
      description: description,
      cover_image_url: cover_image_url,
      book_id: book&.id
    }
  end

  def self.fallback_lookup(clean_isbn, create_associations, create_book)
    url = URI("https://openlibrary.org/isbn/#{clean_isbn}.json")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.open_timeout = 8
    http.read_timeout = 8

    res = http.request(Net::HTTP::Get.new(url))
    return { success: false, error: "No book found for ISBN: #{clean_isbn}" } unless res.is_a?(Net::HTTPSuccess)

    data = JSON.parse(res.body)
    title = data["title"]
    pub_date = data["publish_date"].to_s
    year_match = pub_date.match(/\b(1\d{3}|20\d{2})\b/)
    publication_year = year_match ? year_match[0].to_i : nil
    cover_image_url = "https://covers.openlibrary.org/b/isbn/#{clean_isbn}-L.jpg"

    # Resolve author key if available
    author_name = nil
    if data["authors"].is_a?(Array) && data["authors"].any?
      author_key = data["authors"].first["key"]
      author_name = fetch_author_by_key(author_key)
    end
    author_name ||= "Unknown Author"

    # Extract subjects
    subjects = Array(data["subjects"]).map(&:to_s)
    category_name = determine_category(subjects)

    author = find_or_create_author(author_name, persist: create_associations)
    category = find_or_create_category(category_name, persist: create_associations)

    book = nil
    if create_book
      description_text = data["description"].is_a?(Hash) ? data["description"]["value"] : data["description"].to_s
      book = find_or_create_book(clean_isbn, title, author, category, publication_year, description_text, cover_image_url)
    end

    {
      success: true,
      isbn: clean_isbn,
      title: title,
      author_name: author&.name || author_name,
      author_id: author&.id,
      category_name: category&.name || category_name,
      category_id: category&.id,
      publication_year: publication_year,
      description: data["description"].is_a?(Hash) ? data["description"]["value"] : data["description"].to_s,
      cover_image_url: cover_image_url,
      book_id: book&.id
    }
  rescue StandardError => e
    { success: false, error: "Open Library fallback error: #{e.message}" }
  end

  def self.fetch_author_by_key(author_key)
    return nil if author_key.blank?
    clean_key = author_key.start_with?("/") ? author_key : "/#{author_key}"
    url = URI("https://openlibrary.org#{clean_key}.json")
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 5
    res = http.request(Net::HTTP::Get.new(url))
    return nil unless res.is_a?(Net::HTTPSuccess)
    author_data = JSON.parse(res.body)
    author_data["name"]&.strip
  rescue StandardError
    nil
  end

  def self.determine_category(raw_subjects)
    subjects = Array(raw_subjects).map do |s|
      s.is_a?(Hash) ? s["name"].to_s : s.to_s
    end.map(&:strip).reject(&:blank?)

    return "General" if subjects.empty?

    sub_lowers = subjects.map(&:downcase)

    # 1. Check against curated canonical genres (ordered by genre specificity)
    CANONICAL_GENRES.each do |genre, keywords|
      keywords.each do |kw|
        if sub_lowers.any? { |s| s.include?(kw) }
          return genre
        end
      end
    end

    # 2. Check if any custom Category in DB matches any subject
    if defined?(Category)
      existing_categories = Category.all.to_a
      existing_categories.each do |cat|
        c_name = cat.name.downcase.strip
        if sub_lowers.any? { |s| s == c_name || s.include?(c_name) }
          return cat.name
        end
      end
    end

    # 3. Clean up the first non-noisy subject
    clean_candidate = subjects.find do |s|
      down = s.downcase
      !down.include?(":") &&
        !down.include?("staff pick") &&
        !down.include?("reading level") &&
        !down.include?("grade") &&
        !down.include?("accessible book") &&
        !down.include?("protected daisy") &&
        !down.include?("open library") &&
        !down.include?("syllabus") &&
        !down.include?("overdrive") &&
        !down.include?("translations") &&
        !down.include?("language materials") &&
        !down.include?("large type") &&
        s.length <= 40
    end

    if clean_candidate.present?
      clean_candidate.split.map(&:capitalize).join(" ")
    else
      "General"
    end
  end

  def self.find_or_create_author(author_name, persist: true)
    return nil if author_name.blank? || !defined?(Author)
    clean_name = author_name.strip

    author = Author.where("LOWER(TRIM(name)) = ?", clean_name.downcase).first
    if author.nil? && persist
      author = Author.create(name: clean_name)
    end
    author
  end

  def self.find_or_create_category(category_name, persist: true)
    return nil if category_name.blank? || !defined?(Category)
    clean_name = category_name.strip

    category = Category.where("LOWER(TRIM(name)) = ?", clean_name.downcase).first
    if category.nil? && persist
      category = Category.create(name: clean_name)
    end
    category
  end

  def self.find_or_create_book(clean_isbn, title, author, category, publication_year, description, cover_image_url)
    return nil unless defined?(Book)
    book = Book.where("REPLACE(REPLACE(isbn, '-', ''), ' ', '') = ?", clean_isbn).first
    book ||= Book.new(isbn: clean_isbn)
    book.title = title.presence || "Untitled Book"
    book.author = author if author
    book.category = category if category
    book.publication_year = publication_year || Time.current.year
    book.description = description if description.present?
    book.cover_image_url = cover_image_url if cover_image_url.present?
    book.available = true if book.available.nil?
    book.save
    book
  end
end
