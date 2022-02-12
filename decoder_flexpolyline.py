import flexpolyline as fp
import numpy as np
import sys

def decoder_flexpolyline():

    polyline = sys.argv[1]
    polyline_decoded=fp.decode(polyline)
    coordinates=[[z[i] for z in polyline_decoded] for i in (0,1)]
    np.savetxt('latitudes.txt',coordinates[0])
    np.savetxt('longitudes.txt',coordinates[1])

if __name__ == '__main__':
    decoder_flexpolyline()