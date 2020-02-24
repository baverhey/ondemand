# config/initializers/ood_appkit.rb
require "ood_core"

#ENV['OOD_CLUSTERS'] = '/users/sysp/tdockendorf/git/ondemand/apps/activejobs/clusters.d'
OODClusters = OodCore::Clusters.new(
  OodAppkit.clusters.select(&:job_allow?)
)
