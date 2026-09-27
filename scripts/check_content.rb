# Run with: bundle exec ruby scripts/check_content.rb
require 'yaml'
require 'date'

def yaml(text)
  YAML.safe_load(text, permitted_classes: [Date, Time], aliases: true)
end

def assert(condition, message)
  abort(message) unless condition
end

works = yaml(File.read('_data/works.yml'))
projects = yaml(File.read('_data/projects.yml'))
publications = Dir['_publications/*.md'].map do |path|
  record = yaml(File.read(path).split(/^---\s*$/, 3)[1])
  assert(works.key?(record['work_id']), "Missing shared work data: #{path}")
  assert(%w[en zh].include?(record['locale']), "Missing locale: #{path}")
  if (image = record.dig('header', 'teaser'))
    assert(File.file?("images/#{image}"), "Missing image: #{path}: #{image}")
  end
  record
end
assert(publications.map { |p| p['permalink'] }.uniq.size == publications.size, 'Duplicate publication permalink')
publications.group_by { |p| p['work_id'] }.each do |id, pair|
  assert(pair.size == 2 && pair.map { |p| p['locale'] }.sort == %w[en zh], "Incomplete bilingual pair: #{id}")
  en, zh = pair.sort_by { |p| p['locale'] }
  %w[date venue paperurl projecturl tags].each do |field|
    # Journal/venue names may be translated into Chinese.
    next if field == 'venue'
    assert(en[field] == zh[field], "Locale mismatch: #{id}: #{field}")
  end
  assert(zh['permalink'] == "/zh#{en['permalink']}", "Translation permalink mismatch: #{id}")
  assert(works[id]['year'].is_a?(Integer), "Missing publication year: #{id}")
  assert(%w[agents generative optimization bim resilience].include?(works[id]['topic']), "Unknown topic: #{id}")
end
assert(works.size * 2 == publications.size, 'Orphan shared work record')
assert(projects.map { |p| p['id'] }.uniq.size == projects.size, 'Duplicate project ID')
projects.each do |project|
  %w[en zh].each do |locale|
    %w[label description features linklabel].each do |field|
      assert(project.dig(field, locale), "Missing project translation: #{project['id']}: #{field}/#{locale}")
    end
  end
  %w[image image_zh].each do |field|
    assert(File.file?("images/#{project[field]}"), "Missing project image: #{project['id']}") if project[field]
  end
end
lead = publications.count { |p| p['locale'] == 'en' && (p['tags'] & %w[firstauthor cofirst]).any? }
puts "OK: #{works.size} works / #{publications.size} locale entries; #{lead} first/co-first; #{projects.size} projects."
