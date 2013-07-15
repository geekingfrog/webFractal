module.exports = (grunt) ->
  grunt.option('foo', 'nice foo')
  grunt.initConfig(
    pkg: grunt.file.readJSON 'package.json'

    coffee: {
      compile:
        expand: true
        cwd: './'
        src: ['**/*.coffee']
        ext: '.js'
    } # end coffee

    bower: {
      install: {}
    }

  )

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-bower-task'

  grunt.registerTask 'default', [ 'coffee:compile' ]
