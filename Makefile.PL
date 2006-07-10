use ExtUtils::MakeMaker;
use strict;

WriteMakefile(
    'NAME'     => 'XML2',
    'VERSION_FROM'   => 'XML2.pm',
    'PREREQ_PM'  => {
    'Pod::Usage'         => 0,
    'XML::SAX::PurePerl' => 0,
    },
    'PMLIBDIRS'       => [ 'lib' ],
    'AUTHOR'        => "Martin Owens <DoctorMO{atta}gmail.com>",
);

