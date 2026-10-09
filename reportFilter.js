function filterstreamitem()
{
    var LAT_MIN = 10.00, LAT_MAX = 10.50, LON_MIN = 20.00, LON_MAX = 20.50; // example Region A box
    var MAX_SPEED_KMH = 250;
    var item = getfilterstreamitem();
    if (!item.data || !item.data.json) return "Report must be JSON";
    var r = item.data.json;
    if (!r.session || !r.suspect || !r.event) return "Missing session, suspect or event";
    if (item.keys.length != 2 || item.keys[0] != r.session || item.keys[1] != r.suspect)
        return "Keys must be [session, suspect]";
    if (item.publishers.indexOf(r.suspect) >= 0) return "Self-report rejected";
    if (typeof r.speed_kmh != "number" || r.speed_kmh < 0 || r.speed_kmh > MAX_SPEED_KMH)
        return "Implausible speed";
    if (r.lat < LAT_MIN || r.lat > LAT_MAX || r.lon < LON_MIN || r.lon > LON_MAX)
        return "Position outside Region A";
    if (!verifypermission(r.suspect, "receive")) return "Suspect is not a registered vehicle";
}
