from scipy.cluster.hierarchy import linkage
from skbio.tree import TreeNode
from skbio.stats.distance import DistanceMatrix
from skbio.tree import nj
import os.path
import sys


def single_file_upgma(input_file, output_file):
    # read in dist matrix
    dist_mat = DistanceMatrix.read(input_file)

    # SciPy uses average as UPGMA:
    # http://docs.scipy.org/doc/scipy/reference/generated/
    #    scipy.cluster.hierarchy.linkage.html#scipy.cluster.hierarchy.linkage
    linkage_matrix = linkage(dist_mat.condensed_form(), method='average')

    tree = TreeNode.from_linkage_matrix(linkage_matrix, dist_mat.ids)
    print(tree)
    # write output
    f = open(output_file, 'w')
    try:
        f.write(str(tree))
    except AttributeError:
        #if c is None:
        #    raise RuntimeError("""input file %s did not make a UPGMA tree. Ensure it has more than one sample present""" % (str(input_file),))
        raise
    f.close()

if __name__ == "__main__":
    single_file_upgma(sys.argv[1],sys.argv[2])# test.matrix.txt tree.out
