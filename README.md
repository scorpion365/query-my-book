# README

A basic rails app that answers your questions on Lorem Ipsum book(PDF can be found in `/app/scripts/book.pdf/`). The embeddings have been generated on this pdf using the script `pdf_to_pages_embeddings.rb` located in `app/scripts` as well.
You can use it to generate your own embeddings.

# Instructions
To run this app locally clone the repo and create a `.env` file in the root directory.

Add the following values to the `.env` file:
* OPENAI_ACCESS_TOKEN=Your_openai_access_token
* HOSTNAME="http://127.0.0.1:3000"

Use `yarn` to install the FE dependencies. Tested on node version `16.13.0`.

Use `bundle` to install rails dependencies (Rails version: `7.0.4`, Ruby version `3.1.2)

Run `rails db:migrate`
and then `rails s` to start the server.


The app is live at: [http://query.niche.community](http://query.niche.community).