#*****************************************************************************
#       Copyright (C) 2014 Balazs Strenner <strenner@math.wisc.edu>,
#
#  Distributed under the terms of the GNU General Public License (GPL)
#
#    This code is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#    General Public License for more details.
#
#  The full text of the GPL is available at:
#
#                  http://www.gnu.org/licenses/
#*****************************************************************************
r"""
Script for drawing Area and Tree Models of simple probability experiments.

Each class and function is briefly documented. For examples, see the
end of this file.

"""

from collections import namedtuple

Happening_ = namedtuple('Happening', 'name, probability, next_happenings')

class Happening(Happening_):
    """
    A probabilistic happening.

    The unusual name "happening" is used to avoid the more
    natural English words "outcome" and "event" that mean something else
    in the language of probability.

    ATTRIBUTES:

    - ``name`` -- the name of the happening
    - ``probability`` -- the probability of the happening
    - ``next_happenings`` -- the list of possible happenings following
    this one.
    """
    pass

def get_list_of_happenings(choices, repeats = 1, replacing = True):
    """
    Returns a list of possible happenings for randomly picking from a
    set of choices.

    INPUT:

    - ``choices`` -- a list of choices or a string consisting of
    letters encoding the choices

    - ``repeats`` -- the number of times the picking is repeated

    - ``replacing`` -- boolean, if True, the picked object is replaced
    and can be picked in subsequent repeats, otherwise there are one
    less choice is every subsequent repeat

    OUTPUT:

    - the list of first level happenings. If ``repeats`` was more than
    one, then these first level happenings contain the second level
    happenings in their ``next_happenings`` and so on.
    
    """
    if repeats == 0:
        return []
    if not isinstance(choices, (list, str)):
        raise ValueError("The choices should be specified in "
                "a list or string.")
    if isinstance(choices, str):
        choices = list(choices)
    count = {choice : choices.count(choice) for choice in choices}
    total = len(choices)

    def new_choices(index_of_choice):
        if replacing:
            return choices
        else:
            new_list = list(choices)
            del new_list[index_of_choice]
            return new_list

    return [Happening(name = choices[index], 
        probability = Rational((count[choices[index]],total)), 

        next_happenings = get_list_of_happenings(new_choices(index), 
            repeats - 1, replacing))
            for index in range(len(choices)) if
            index == choices.index(choices[index])]

class Experiment:
    """
    A probability experiment.

    INPUT:

    - ``happenings`` -- the list first level happenings (which should
    already contain the list of next happenings and those the next
    ones, and so on, as a tree.
    """
    def __init__(self, happenings):
        self._root = Happening("", 1, happenings)

    @property
    def root(self):
        """
        The root happening of the experiment.

        The root does not have a name, its probability is 1, and its
        next_happenings list contains the first-level happenings.
        """
        return self._root

    @classmethod
    def picking(cls, choices, repeats = 1, replacing = True):
        """
        Constructs an Experiment for the common scenario that we
        randomly pick from a set of choices.
        """
        return Experiment(get_list_of_happenings(choices, repeats, 
            replacing))

class AreaModel(SageObject):
    """ Area model of an Experiment. """
    separator = ""

    def __init__(self, experiment):
        self._experiment = experiment


    def _latex_(self):
        """ Returns the latex representation of the area model. """
        
        fontsize = '\\footnotesize'
        latex.add_to_preamble('\\usepackage{tikz}')
        s = "\\begin{tikzpicture}[scale = 3]\n"
        s += "\\colorlet{fillingcolor}{green!30}\n"
        s += "\\tikzstyle innerline=[dashed]\n"
        s += "\\tikzstyle edgelabel=[font=\\footnotesize]\n"
        s += "\\foreach \\yone/\\ytwo/\\outcomenameone/\\outcomeprobone/"\
             "\\secondlist in {\n"

        first_row_s = "\\foreach \\xone/\\xtwo/\\outcomenametwo/"\
                      "\\outcomeprobtwo in {\n"
        y = 0
        nrows = len(self._experiment.root.next_happenings)
        for row_count in range(nrows):
            hap1 = self._experiment.root.next_happenings[row_count]
            haps = hap1.next_happenings
            if len(haps) == 0:
                haps = [Happening("", 1, [])]

            y1 = round(-y, 4)
            y2 = round(-y - hap1.probability, 4)

            s += "\t{y1}/{y2}/{outcome1name}/{prob}/{{\n".format(
                y1 = y1, y2 = y2, outcome1name = hap1.name,
                prob = latex(hap1.probability))

            x = 0
            for col_count in range(len(haps)):
                hap2 = haps[col_count]
                if len(hap2.next_happenings) > 0:
                    raise ValueError("We cannot draw an area \
                            model if the decision tree goes \
                            more than two levels deep.")
                x1 = round(x, 4)
                x2 = round(x + hap2.probability, 4)

                s += "\t\t{x1}/{x2}/{outcome2name}/{prob}/{fillcolor},\n".\
                     format(x1 = x1, x2 = x2, outcome2name = hap2.name,
                            prob = latex(hap2.probability),
                            fillcolor = "none")
                if row_count == 0:
                    first_row_s += "\t{x1}/{x2}/{outcome2name}/{prob},\n".\
                        format(x1 = x1, x2 = x2, outcome2name = hap2.name,
                            prob = latex(hap2.probability))
                    
                x += hap2.probability
            
            s = s[:-2] + "},\n"
            y += hap1.probability
        s = s[:-2] + "}\n{\n"
        s += "\t% label probabilities on the left\n"
        s += "\t\\path (0,\\yone) -- node[left,edgelabel] {$\\outcomeprobone$} "\
             " (0,\\ytwo);\n"

        s += "\t% label probabilities on the right\n"
        s += "\t%\\path (1,\\yone) -- node[right,edgelabel] {$\\outcomeprobone$} "\
             " (1,\\ytwo);\n"

        s += "\t% label outcome name on the left\n"
        s += "\t%\\path (0,\\yone) -- node[left,edgelabel] {\\outcomenameone} "\
             " (0,\\ytwo);\n"

        s += "\t% draw horizontal separating lines\n"
        s += "\t\\draw[innerline] (0,\\yone) -- (1,\\yone);\n"
        s += "\t\\foreach \\xone/\\xtwo/\\outcomenametwo/\\outcomeprobtwo/\\fillcolor in "\
             "\\secondlist {\n"
        s += "\t\t% fill cells\n"
        s += "\t\t\\path[fill=\\fillcolor] (\\xone, \\yone) rectangle (\\xtwo, \\ytwo);\n"

        s += "\t\t% label the outcomes in the center of the boxes\n"
        s += "\t\t\\path (\\xone, \\yone) -- node {\\outcomenameone\\outcomenametwo} "\
             "(\\xtwo, \\ytwo);\n"
        
        s += "\t\t% label the width of the cells in the cells\n"
        s += "\t\t%\\path (\\xone, \\ytwo) -- node[above,edgelabel] {$\\outcomeprobtwo$} "\
             "(\\xtwo, \\ytwo);\n"

        s += "\t\t% vertical separating lines\n"
        s += "\t\t\\draw[innerline] (\\xone, \\yone) -- (\\xone, \\ytwo);\n"
        s += "\t}\n}\n"

        s += first_row_s[:-2] + "}\n{\n"
        
        s += "\t% draw width of cells once on top\n"
        s += "\t\\path (\\xone, 0) -- node[above,edgelabel] "\
             "{$\\outcomeprobtwo$} (\\xtwo, 0);\n"

        s += "\t% draw width of cells once on bottom\n"
        s += "\t%\\path (\\xone, -1) -- node[below,edgelabel] "\
             "{$\\outcomeprobtwo$} (\\xtwo, -1);\n"

        s += "\t% draw outcome names once on top\n"
        s += "\t%\\path (\\xone, 0) -- node[above,edgelabel] "\
             "{\\outcomenametwo} (\\xtwo, 0);\n"

        s += "}\n"
        s += "\\draw (0,0) rectangle (1, -1);\n"
        s += "\\end{tikzpicture}\n"
        return s



    def _latex_old(self):
        """ The older version of the _latex_ method.

        This one doesn't use many foreach loops, so the tikz code gets
        longer and some things take longer to customize, but
        customization is more flexible than for the other _latex_
        method.
        """
        
        fontsize = '\\footnotesize'
        latex.add_to_preamble('\\usepackage{tikz}')
        s = "\\begin{tikzpicture}[scale = 3]\n"
        s += "\\colorlet{fillingcolor}{green!30}\n"
        s += "% To change the color of individual rectangles, simply replace "\
                "fill=none by fill=fillingcolor for the appropriate rectangles.\n"

        vlabeldata = []
        labels = "% Labels: Play with the 'above' and 'below' options, "\
                "changing the y-coordinates of row-labels, or deleting "\
                "labels of certain rows completely.\n"
        y = 0
        nrows = len(self._experiment.root.next_happenings)
        for row_count in range(nrows):
            hap1 = self._experiment.root.next_happenings[row_count]
            haps = hap1.next_happenings
            hlabeldata = []
            separator = self.separator
            if len(haps) == 0:
                haps = [Happening("", 1, [])]
                separator = ""
            x = 0
            s += "% row {0}\n".format(row_count)
            for col_count in range(len(haps)):
                hap2 = haps[col_count]
                if len(hap2.next_happenings) > 0:
                    raise ValueError("We cannot draw an area \
                            model if the decision tree goes \
                            more than two levels deep.")
                temp = "\\path[fill=none] ({x1}, {y1}) rectangle ({x2}, {y2}); " \
                        "% col {col}\n"
                if col_count > 0:
                    temp += "\\draw[dashed] ({x1},{y1}) -- ({x1},{y2});\n"
                if row_count > 0:
                    temp += "\\draw[dashed] ({x1},{y1}) -- ({x2},{y1});\n"
                x1 = round(x, 4)
                y1 = round(-y, 4)
                x2 = round(x + hap2.probability, 4)
                y2 = round(-y - hap1.probability, 4)
                mx = round(x + hap2.probability/2, 4)
                my = round(-y - hap1.probability/2, 4)

                s += temp.format(x1 = x1, x2 = x2, y1 = y1, y2 = y2,
                        col = col_count)
                s += "\\node at ({mx}, {my}) {{{name}}};\n".format(
                        mx = mx, my = my,
                        name = hap1.name + separator + hap2.name)
                x += hap2.probability
                hlabeldata.append(str(mx) + '/' + latex(hap2.probability))
            if row_count == 0:
                pos = "above"
            elif row_count == nrows - 1:
                pos = "below"
            else:
                pos = ""
            labels += "\\foreach \\x/\\xtext in {{{data}}}\n"\
                    "\t\\node[{pos},font={fontsize}] at (\\x,-{y}) {{$\\xtext$}};"\
                    " % row {row_count}\n".\
                    format(data = ",".join(hlabeldata),
                        y = y if 2*row_count<nrows else y+hap1.probability, 
                        pos = pos, row_count = row_count,
                        fontsize = fontsize)

            vlabeldata.append(str(round(y + hap1.probability/2, 4)) + '/' +
                    latex(hap1.probability))
            y += hap1.probability

        labels += "\\foreach \\y/\\ytext in {{{data}}}\n"\
                "\t\\node[left,font={fontsize}] at (0,-\\y) {{$\\ytext$}};"\
                "% vertical labels\n".\
                format(data = ",".join(vlabeldata),
                        fontsize=fontsize)
        s += labels
        s += "\\draw (0,0) rectangle (1, -1);\n"
        s += "\\end{tikzpicture}\n"
        return s



    

         
class TreeModel(SageObject):
    """ Tree model of an Experiment. """
    
    __level_distance = '1.5cm'
    __sibling_distances = ['2 cm', '1 cm', '0.5 cm']
    
    def __init__(self, experiment, draw_labels = True):
        self._experiment = experiment
        self._draw_labels = draw_labels

    def _tikz_tree_of_happening_(self, happening, probability_so_far, 
            node_name_so_far, total_prob_string_list):
        """ Recursively called method to generate tikz code. """
        
        s = "\tchild[norm] {{node ({nodename}) [happening] {{{name}}}\n".\
                format(name = happening.name, nodename = node_name_so_far)
        total_prob = probability_so_far * happening.probability
        count = 0
        for child in happening.next_happenings:
            s += self._tikz_tree_of_happening_(child, total_prob, 
                    node_name_so_far + '-' + str(count + 1),
                    total_prob_string_list)
            count += 1
        s += "\t\tedge from parent\n"
        if self._draw_labels:
            s += "\t\tnode [left,label] {{${prob}$}}\n".format(prob = 
                    latex(happening.probability))
        if len(happening.next_happenings) == 0:
            total_prob_string_list.append("\\node ({nodename}-total) "\
                    "[below =0.5cm of {nodename},"\
                    "purple] {{${total_prob}$}};\n".\
                    format(nodename = node_name_so_far,
                            total_prob = latex(total_prob)))
            total_prob_string_list.append("\\draw[->,dashed,green!60!black] ({nodename}.south) "
                    "-- ({nodename}-total.north);\n".format(\
                            nodename = node_name_so_far))

        s += '\t}\n'
        return s
        

    def _latex_(self):
        """ Returns the LaTeX/TikZ representation of self. """
        
        latex.add_to_preamble('\\usepackage{tikz}')
        latex.add_to_preamble('\\usetikzlibrary{positioning}')
        s = "\\begin{{tikzpicture}}[\n"\
                "\tlevel distance={0},\n"\
                "\tlevel 1/.style={{sibling distance = {1}}},\n"\
                "\tlevel 2/.style={{sibling distance = {2}}},\n"\
                "\tlevel 3/.style={{sibling distance = {3}}},\n"\
                "\temph/.style={{edge from parent/.style={{red,very thick,draw}}}},\n"\
                "\tnorm/.style={{edge from parent/.style={{black,thin,draw}}}}\n"\
                "]\n".format(self.__level_distance, *self.__sibling_distances)

        s += "% Change circle to rectangle for a different look\n"
        s += "\\tikzstyle happening= [circle, draw=black,thin,fill=yellow!30]\n"

        s += "\\coordinate\n"
        total_prob_string_list = []
        count = 0
        for child in self._experiment.root.next_happenings:
            s += self._tikz_tree_of_happening_(child, 1, str(count + 1),
                    total_prob_string_list)
            count += 1
        s = s[:-1] + ';\n'
        if self._draw_labels:
            s += "% Probabilities of outcomes\n"
            s += "".join(total_prob_string_list)
        s += "\\end{tikzpicture}\n"
        return s




# predefined experiment for problems in the Math 132 course packet
math132_1_3_0_dice = Experiment.picking('123456', repeats = 1)
math132_1_3_0 = Experiment.picking('QQDN', repeats = 1)
math132_1_3_0_d = Experiment.picking(['Q$_1$', 'Q$_2$', 'N', 'D'],
        repeats = 1)
math132_1_3_1_verbose = Experiment.picking(['quarter', 'quarter', 'dime', 'nickel'],
        repeats = 2, replacing = False)
math132_1_3_1 = Experiment.picking('QQDN',
        repeats = 2, replacing = False)
math132_1_3_2 = Experiment.picking(['Q$_1$', 'Q$_2$', 'N', 'D'], 
        repeats = 2, replacing = False)
math132_1_3_3 = Experiment.picking('1234', repeats = 2,
        replacing = True)
math132_1_3_4 = Experiment.picking('BBBR', repeats = 2,
        replacing = True)

h1 = Happening('red', Rational((2,5)), 
        get_list_of_happenings(['cherry', 'grape', 'apple']))
h2 = Happening('white', Rational((3,5)),[])
math132_1_4_1 = Experiment([h1, h2])

h1 = Happening('red', Rational((1,5)), 
        get_list_of_happenings(['cherry', 'grape', 'apple']))
h2 = Happening('white', Rational((1,5)),[])
math132_1_4_2 = Experiment([h1,h1,h2,h2,h2])

hprecip = Happening('precip', 1/4, [])
hnoprecip = Happening('noprecip', 3/4, [])
hcold = Happening('cold', 4/5, [hprecip, hnoprecip])
hwarm = Happening('warm', 1/5, [hprecip, hnoprecip])
math132_1_4_3 = Experiment([hcold, hwarm])

h1 = Happening('1', 3/5, [])
h2 = Happening('0', 2/5, [])
math132_1_4_4_a = Experiment([Happening('1',3/5,[h1,h2]),
    Happening('0',2/5,[h1,h2])])

h1 = Happening('1', 4/5, [])
h2 = Happening('0', 1/5, [])
h3 = Happening('1', 1/2, [])
h4 = Happening('0', 1/2, [])
math132_1_4_4_b = Experiment([Happening('1',3/5,[h1,h2]),
    Happening('0',2/5,[h3,h4])])

suits = ["$\diamondsuit$", "$\heartsuit$",
                                    "$\spadesuit$", "$\clubsuit$"]
math132_1_5_1 = Experiment.picking(suits)

rank_haps = get_list_of_happenings(['A',
                                '2','3','4','5','6','7','8','9','10','J','Q','K'])
math132_1_5_1b = Experiment([Happening(suit,1/4,rank_haps) for suit in
                                suits])

math132_1_5_5 = Experiment.picking('123456', repeats = 2,
                                   replacing = True)

math132_1_7_1 = Experiment.picking(['cherry', 'lemon', 'lemon'], repeats = 3)
math132_1_7_2 = Experiment.picking('HT', repeats = 2)

h1 = Happening('storm', 1/10, [])
h2 = Happening('no storm', 9/10, [])
h3 = Happening('storm', 4/10, [])
h4 = Happening('no storm', 6/10, [])
math132_1_7_4 = Experiment([Happening('warm', 3/4, [h1, h2]),
                            Happening('hot', 1/4, [h3, h4])])
