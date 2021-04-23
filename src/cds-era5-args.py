import cdsapi
import argparse

text = 'Download cds data with command date selections.'

parser = argparse.ArgumentParser(description=text)
parser.add_argument("-V", "--version", help="show program version", action="store_true")
parser.add_argument("-y", "--years", nargs='+', help="set download years (required), e.g. -y 2020 2021")
parser.add_argument("-m", "--months", nargs='+', help="set download months (required), e.g. -m 01 02 03")
parser.add_argument("-d", "--days", nargs='+', help="set download days, e.g. -d 10 11 12; if not set, will default to all days (01 - 31)")
parser.add_argument("-o", "--output", help="set output file name, e.g. -o myfilename")

args = parser.parse_args()



if args.version:
    print("This is version 0.1 of the CDS download script")
if args.years:
    print("Download for year(s) %s" % args.years)
if args.months:
    print("Download for month(s) %s" % args.months)

if args.days:
	dldays = args.days
	print("Download for day(s) %s" % dldays)
else:
	dldays = ['01', '02', '03',
            '04', '05', '06',
            '07', '08', '09',
            '10', '11', '12',
            '13', '14', '15',
            '16', '17', '18',
            '19', '20', '21',
            '22', '23', '24',
            '25', '26', '27',
            '28', '29', '30',
            '31']
	print("Download for day(s) %s" % dldays)

if args.output:
	filename = 'data/' + args.output + '.grib'
	print("Output file will be saved at %s" % filename)
else:
	filename = 'data/download.grib'
	print("Output file will be saved at %s" % filename)

# need to have the specified arguments for the script to run
if args.years and args.months and dldays:
	# do all the CDS stuff
	c = cdsapi.Client()
	
	c.retrieve(
    'reanalysis-era5-pressure-levels',
    {
        'product_type': 'reanalysis',
        'variable': 'temperature',
        'pressure_level': '1000',
        'year': args.years,
        'month': args.months,
        'day': dldays,
        'time': [
            '00:00', '01:00', '02:00',
            '03:00', '04:00', '05:00',
            '06:00', '07:00', '08:00',
            '09:00', '10:00', '11:00',
            '12:00', '13:00', '14:00',
            '15:00', '16:00', '17:00',
            '18:00', '19:00', '20:00',
            '21:00', '22:00', '23:00',
        ],
        'format': 'grib',
    },
    filename)
else:
	print("Error: You didn't specify one of the required arguments - see --help for more details.")
