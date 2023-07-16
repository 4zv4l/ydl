#!/bin/ruby

require 'thor'
require 'fileutils'
require 'net/ssh'
require 'net/scp'

MUSICS = File.expand_path "~/Music/Musics"

class Ydl < Thor
  descs = {
    play:   ["play",            "start the music player"],
    search: ["search",          "search for music in the library"],
    add:    ["add  [URL]",      "add music from URL"],
    rem:    ["rem",             "remove music by name using fzf"],
    sync:   ["sync [get/give]", "sync the music with the server"]
  }

  desc(*descs[:play])
  def play
    exec("ncmpcpp")
  end

  desc(*descs[:search])
  def search
    `ls #{MUSICS} | fzf`.chomp
  end

  desc(*descs[:add])
  def add(url)
    `yt-dlp -x --audio-format mp3 #{url}`
    file = `ls *.mp3`.chomp
    mp3 = "#{File.basename(file, File.extname(file))}.mp3"
    FileUtils.mv(mp3, MUSICS)
  rescue => e
    abort "couldn't download the music: #{e}"
  end

  desc(*descs[:rem])
  def rem
    to_remove = `ls #{MUSICS} | fzf`.chomp
    File.delete("#{MUSICS}/#{to_remove}") unless to_remove == ""
  rescue => e
    abort "couldn't remove the file: #{e}"
  end

  desc(*descs[:sync])
  def sync(action)
    abort "sync: missing argument" if action.nil?
    abort "sync #{action}: wrong argument" if !action =~ /get|give/
    Net::SSH.start("homelab") do |ssh|
      ssh.scp.download!("/DATA/Media/Musics", "#{Dir.home}/Music", recursive: true) if action == "get"
      ssh.scp.upload!(MUSICS, "/DATA/Media/", recursive: true) if action == "give"
    end
  rescue => e
    abort "couldn't sync: #{e}"
  end

  def self.exit_on_failure?
    true
  end
end

Ydl.start
