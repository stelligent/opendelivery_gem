pipelines = []

pipelines.add(["trigger", "commit", "acceptance"])
pipelines.add(["deploy-to-ruby-gems"])
pipelines.each { jobs ->
for (i = 0; i < jobs.size; ++ i) {
    job {
        name "${jobs[i]}-dsl"
        scm {
            git("https://github.com/stelligent/honolulu_answers.git", "master") { node ->
                node / skipTag << "true"
            }
        }
      if (jobs[i].equals("trigger-stage")) {
          triggers {
            scm("* * * * *")
          }
      }
      steps {
        shell("pipeline/${jobs[i]}.sh")
        if (i + 1 < jobs.size) {
          downstreamParameterized {
            trigger ("${jobs[i+1]}-dsl", "ALWAYS"){
              currentBuild()
              propertiesFile("environment.txt")
            }
          }
        }
      }
      wrappers {
          rvm("2.0.0")
      }
      publishers {
        extendedEmail("jonny@stelligent.com", "\$PROJECT_NAME - Build # \$BUILD_NUMBER - \$BUILD_STATUS!", """\$PROJECT_NAME - Build # \$BUILD_NUMBER - \$BUILD_STATUS:

  Check console output at \$BUILD_URL to view the results.""") {
            trigger("Failure")
            trigger("Fixed")
        }
      }
    }
  }
}