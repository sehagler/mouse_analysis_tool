The csv file aggregates all the available mouse data for the period indicated.  Mouse movement data is aggregated in 3 different ways.  The first way aggregates all mouse data and is indicated by a variable 'X'.  The second way aggregates only class I mouse movements and is indicated by a variable 'X I'.  The third way aggregates only class II mouse movements and is imdicated by a variable 'X II'.  The two classes of mouse movements do not have any movements in common.  All mouse movements are classified as either class I or class II.

Notes on variables:

N sessions - number of sessions of computer usage appearing in the period
N moves - total number of moves analyzed (this is NOT the total number of moves, as data may be eliminated if needed to avert memory issues).
N moves I - the total number of class I moves analyzed (the number of moves analyzed that were class I).
N moves II - the total number of class II moves analyzed.

As the N moves value may have trimmed data, they shouldn't be analyzed, but the ratios N moves I / N moves or N moves II / N moves should be okay for analysis.

You may want to consider dropping periods where the number of moves analyzed gets too low (I don't know what 'too low' is).

Also note that some variables a characterized by the mean and standard deviation and others by the median and inter-quartile range (iqr).

rho - this is related to how the division of the data into individual moves was made.  It seemed to provide useful information about TMT.

Delta, Delta I, Delta II - the net distance traveled by the mouse in counts (i.e. straightline distance between starting and ending points)

D, D I, D II - the total distance traveled by the mouse in counts.

K, K I, K II - the net distance traveled by the mouse divided by the total distance, a rudimentary movement curvature measure.

T, T I, T II - the time taken to make a mouse movement in msec.

[a_tilde, b], [a_tilde I, b I], [a_tilde II, b II] - parameter values of Fitts' law when fit to the data.  These values should be analyzed in the indicated pairs.

tauM, tauM I, tauM II - the parameter value of an alternate formulation of Fitts' law.

idle, idle I, idle II - the time spent idling or pausing between successive movements in msec.