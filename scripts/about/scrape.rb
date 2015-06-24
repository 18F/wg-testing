require 'json'
require 'octokit'
require 'safe_yaml'
require 'base64'


SafeYAML::OPTIONS[:default_mode] = :safe
Octokit.auto_paginate = true
repos = []

def get_access_key
  fh = File.open('.github_token', 'r')
  key = fh.read
  fh.close
  return key
end


puts 'Started. Fetching 18F public repos from the Github API...'
client = Octokit::Client.new(:access_token => get_access_key)
repos = client.org_repos '18F', { :type => 'public' }

puts "Found #{repos.length} repos."

puts 'Searching for .about.yml on each one...'
raw_yml = []
missing_abouts = []

repos.each do |repo|
  about_yml = nil
  begin
    about_yml = client.contents repo.full_name, { :path => '.about.yml' }
    raw_yml.push(about_yml)
  rescue Octokit::NotFound
    missing_abouts.push(repo.name)
  end
end

puts "Found #{raw_yml.length} files. #{missing_abouts.length} didn't have an .about.yml (see '18f_about_missing.yml' for which ones)."

puts 'Munging YAML into a master file...'
full_yml = {}
raw_yml.each do |yml|
  contents = Base64.decode64(yml['content'])
  cont_obj = YAML.load(contents)

  owner_type, short_name = cont_obj['owner_type'], cont_obj['short_name']
  if owner_type and short_name
    full_yml[owner_type] ||= {}
    full_yml[owner_type][short_name] = cont_obj
  else
    alt_id = cont_obj['full_name'] ? cont_obj['full_name'] : cont_obj['name']
    alt_id += '/' + cont_obj['type']
    full_yml[alt_id] = cont_obj
  end
end

puts 'Writing master file and missing file...'

# write all YAML files out to a master file
fh = File.open('18f_about.yml', 'w')
fh.write(YAML.dump(full_yml))
fh.close

# log the repos that are missing an .about.yml
fh = File.open('18f_about_missing.yml', 'w')
fh.write(YAML.dump(missing_abouts))
fh.close

puts 'Done. Exiting.'
