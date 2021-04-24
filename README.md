# WikiNG

Copy of the WikiNG Redmine plugin, developed by Andriy Lesyuk at http://projects.andriylesyuk.com/projects/wiking
WikiNG offers additional formatting options for Redmine.

## Original source code

http://subversion.andriylesyuk.com/wiking/

## Documentation

http://projects.andriylesyuk.com/projects/wiking/wiki

## Compatibility

Tested on Redmine 4.1.2.
Should be compatible with 4.x and 3.x

## Downloading and installing the plugin

First download the plugin using git, open a terminal in your Redmine installation directory:

```git clone git@github.com:martin-denizet/wiking ./plugins/```

Then you will need to do migrate the database for the plugin.

``` bundle exec rake redmine:plugins:migrate RAILS_ENV=production```

The installation is now finished and you will be able to use the plugin after you restart your Redmine instance.

## Credits

* Andriy Lesyuk: Original idea and development
* Dave Carlton for the idea of adding syntax reference
* Oleg Kandaurov for assisting in porting the plugin to Redmine 2 / Rails 3
* Ivan Cenov for Bulgarian translation
* Ismail Sezen for Turkish translation
* Ismail Sezen for the idea of the file: link
* Daniel Gloger for patch fixing language in Wikipedia links
* Timothy Miller for the "More" icon
* Yusuke Kamiyamane for the "Success" and "Failure" icons
* Ki Won Kim for Korean translation
* @addow fix issue #3
* @das-peter fixing repeat of icons
* @atopcu Turkish translations

## How to contribute

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

GPLv2

Copyright (C) 2014 Andriy Lesyuk





