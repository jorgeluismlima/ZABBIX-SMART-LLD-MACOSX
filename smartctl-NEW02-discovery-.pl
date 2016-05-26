#!/usr/bin/perl

$first = 1;

print "{\n";
print "\t\"data\":[\n\n";

for (`diskutil list | grep 2:` ){

$smart_avail=0;
$smart_enabled=0;
$smart_enable_tried=0;

@info = split(' ', $_);
$type ="$info[1]";
$disk ="$info[-1]";
chomp($disk);
chomp($type);

print "\t,\n" if not $first;
$first = 0;

#SMART STATUS LOOP
foreach(`/usr/local/sbin/smartctl -i /dev/$disk | grep SMART`){

$line=$_;

	# if SMART available -> continue
	if ($line = /Available/){
		$smart_avail=1;
		next;
		}

	#if SMART is disabled then try to enable it (also offline tests etc)
	if ($line = /Disabled/ & $smart_enable_tried == 0){

		foreach(`/usr/local/sbin/smartctl -i /dev/$disk -s on -o on -S on | grep SMART`) {
			if (/SMART Enabled/){
			$smart_enabled=1;
			next;
			}
		}
	$smart_enable_tried=1;
	}

	if ($line = /Enabled/){
		$smart_enabled=1;
		}
}
	
if ($type eq "Apple_RAID"){
	$UUID = (`diskutil info $disk | grep 'RAID Set UUID:' | cut -d":" -f2`);
	chomp($UUID);
	$Raid_Info = (`diskutil listraid $UUID | grep "Device Node"`);
	$Device_Node = (split(' ' , $Raid_Info))[-1];
	$result = (`mount | grep /dev/$Device_Node | sed s/"on"/","/g | sed s/"(hfs, local, journaled)"/""/g`);
	@Disk_info = split(',' , $result);
	$Disk_Volume = "$Disk_info[-1]";
	chomp($Disk_Volume);

}
else{
	$result = (`diskutil info /dev/$disk | grep "Mount Point"`);
	@Disk_info = split(' ' , $result);
	$Disk_Volume ="$Disk_info[-1]";
	chomp($Disk_Volume);

}

print "\t{\n";
print "\t\t\"{#DISKNAME}\":\"$disk\",\n";
print "\t\t\"{#TYPE}\":\"$type\",\n";
print "\t\t\"{#VOLUME}\":\"$Disk_Volume\",\n";
print "\t\t\"{#SMART_ENABLED}\":\"$smart_enabled\"\n";
print "\t}\n";

}

print "\n\t]\n";
print "}\n";
