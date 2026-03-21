#### Ps if you want to use a domain - this should be the main DNS setup
#### You need to register the domain first in order to use it, so this is just an example

// resource "google_dns_managed_zone" "atlantis-demo-fsouza-zone" {
//   name        = "atlantis-demo-fsouza-zone"
//   dns_name    = "${var.atlantis_demo_dns_domain}."
//   description = "Atlantis DNS Zone"
// 
//   dnssec_config {
//     state         = "off"
//     non_existence = "nsec3"
//   }
// }
// 
// resource "google_dns_record_set" "atlantis-demo-fsouza-zone-soa" {
//   name         = google_dns_managed_zone.atlantis-demo-fsouza-zone.dns_name
//   type         = "SOA"
//   ttl          = 21600
//   managed_zone = google_dns_managed_zone.atlantis-demo-fsouza-zone.name
//   rrdatas      = ["ns-cloud-b1.googledomains.com. cloud-dns-hostmaster.google.com. 1 21600 3600 259200 300"]
// }
// 
// resource "google_dns_record_set" "atlantis-demo-fsouza-zone-ns" {
//   name = google_dns_managed_zone.atlantis-demo-fsouza-zone.dns_name
//   type = "NS"
//   ttl  = 21600
// 
//   managed_zone = google_dns_managed_zone.atlantis-demo-fsouza-zone.name
//   rrdatas = [
//     "ns-cloud-b1.googledomains.com.",
//     "ns-cloud-b2.googledomains.com.",
//     "ns-cloud-b3.googledomains.com.",
//     "ns-cloud-b4.googledomains.com.",
//   ]
// }
// 
// ### Attaching entry to global atlantis LB IP / address
// resource "google_dns_record_set" "atlantis-domain-dns-record" {
//   name         = "atlantis.${google_dns_managed_zone.atlantis-demo-fsouza-zone.dns_name}"
//   managed_zone = google_dns_managed_zone.atlantis-demo-fsouza-zone.name
//   type         = "CNAME"
//   ttl          = 300
//   rrdatas      = [google_dns_managed_zone.atlantis-demo-fsouza-zone.dns_name]
// }
// 
// resource "google_dns_record_set" "backend-domain-dns-record" {
//   name         = google_dns_managed_zone.atlantis-demo-fsouza-zone.dns_name
//   managed_zone = google_dns_managed_zone.atlantis-demo-fsouza-zone.name
//   type         = "A"
//   ttl          = 3600
//   rrdatas      = [google_compute_global_address.atlantis-lb-global-address.address]
// }
// 
// ### SSL certs for our LB
// ### pointing only to atlantis server fow now
// resource "google_compute_managed_ssl_certificate" "atlantis-demo-ssl-cert" {
//   provider = google-beta
//   name     = "atlantis-demo-ssl-cert"
// 
//   managed {
//     domains = [var.atlantis_demo_dns_domain]
//   }
// }
