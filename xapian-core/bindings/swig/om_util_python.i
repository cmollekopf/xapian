%{
/* om_util_python.i: the Xapian scripting python interface helpers.
 *
 * ----START-LICENCE----
 * Copyright 1999,2000,2001 BrightStation PLC
 * Copyright 2002 Ananova Ltd
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License as
 * published by the Free Software Foundation; either version 2 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
 * USA
 * -----END-LICENCE-----
 */
%}
%include typemaps.i

%typemap(python, out) string {
    $target = PyString_FromString(($source)->c_str());
    delete $source;
    $source = 0;
}

%typemap(python, in) const string &(string temp) {
    if (PyString_Check($source)) {
	temp = string(PyString_AsString($source),
		      PyString_Size($source));
	$target = &temp;
    } else {
        PyErr_SetString(PyExc_TypeError, "string expected");
	return NULL;
    }
}

/*
%typemap(python, in) om_queryop &(OmQuery::op qop) {
    try {
        qop = (OmQuery::op)(get_py_int($source));
    } catch (OmPythonProblem &) {
        return NULL;
    }
    $target = &qop;
}
*/

%{
    class OmPythonProblem {};
    OmQuery *get_py_omquery(PyObject *obj)
    {
	OmQuery *retval = 0;
	PyObject *mythis = PyDict_GetItemString(((PyInstanceObject *)obj)
						->in_dict, "this");
	if (char *err = SWIG_GetPtr(PyString_AsString(mythis),
				    (void **)&retval,
				    "_OmQuery_p")) {
	    cerr << "obj.this: " << PyString_AsString(mythis) << endl;
	    cerr << "Problem is: " << err << endl;
	    PyErr_SetString(PyExc_ValueError,
			    "OmQuery object invalid");
	    return 0;
	}
	return retval;
    }

    OmRSet *get_py_omrset(PyObject *obj)
    {
	OmRSet *retval = 0;
	if (PyInstance_Check(obj)) {
	    PyObject *mythis = PyDict_GetItemString(((PyInstanceObject *)obj)
						    ->in_dict, "this");
	    if (char *err = SWIG_GetPtr(PyString_AsString(mythis),
					(void **)&retval,
					"_OmRSet_p")) {
		cerr << "obj.this: " << PyString_AsString(mythis) << endl;
		cerr << "Problem is: " << err << endl;
		PyErr_SetString(PyExc_ValueError,
				"OmRSet object invalid");
		return 0;
	    }
	}
	return retval;
    }

    OmSettings *get_py_omsettings(PyObject *obj)
    {
	OmSettings *retval = 0;
	if (PyInstance_Check(obj)) {
	    PyObject *mythis = PyDict_GetItemString(((PyInstanceObject *)obj)
						    ->in_dict, "this");
	    if (char *err = SWIG_GetPtr(PyString_AsString(mythis),
					(void **)&retval,
					"_OmSettings_p")) {
		cerr << "obj.this: " << PyString_AsString(mythis) << endl;
		cerr << "Problem is: " << err << endl;
		PyErr_SetString(PyExc_ValueError,
				"OmSettings object invalid");
		return 0;
	    }
	}
	return retval;
    }

    OmMatchDecider *get_py_ommatchdecider(PyObject *obj)
    {
	OmMatchDecider *retval = 0;
	if (PyInstance_Check(obj)) {
	    PyObject *mythis = PyDict_GetItemString(((PyInstanceObject *)obj)
						    ->in_dict, "this");
	    if (char *err = SWIG_GetPtr(PyString_AsString(mythis),
					(void **)&retval,
					"_OmMatchDecider_p")) {
		cerr << "obj.this: " << PyString_AsString(mythis) << endl;
		cerr << "Problem is: " << err << endl;
		PyErr_SetString(PyExc_ValueError,
				"OmMatchDecider object invalid");
		return 0;
	    }
	}
	return retval;
    }

    int get_py_int(PyObject *obj) {
	if (!PyNumber_Check(obj)) {
	    throw OmPythonProblem();
	} else {
	    return PyInt_AsLong(PyNumber_Int(obj));
	}
    }
%}

%typemap(python, in) const vector<OmQuery *> *(vector<OmQuery *> v){
    if (!PySequence_Check($source)) {
        PyErr_SetString(PyExc_TypeError, "expected list of queries");
        return NULL;
    }
    int i = 0;
    PyObject *obj;
    while ((obj = PySequence_GetItem($source, i++)) != NULL) {
	if (PyInstance_Check(obj)) {
	    OmQuery *subqp = get_py_omquery(obj);
	    if (!subqp) {
		PyErr_SetString(PyExc_TypeError, "expected query");
		return NULL;
	    }
	    v.push_back(subqp);
	} else {
	    PyErr_SetString(PyExc_TypeError,
			    "expected instance objects");
	    return NULL;
	}
    }
    $target = &v;
}

%typemap(python, in) const OmSettings &(OmSettings s) {
    if (!PyMapping_Check($source)) {
        PyErr_SetString(PyExc_TypeError, "expected string to string map");
        return NULL;
    }
    // return the list of (key, value) tuples
    PyObject *items = PyMapping_Items($source);
    int i = 0;
    PyObject *obj;
    while ((obj = PySequence_GetItem(items, i++)) != NULL) {
	if (PyTuple_Check(obj) && PyTuple_Size(obj) == 2) {
	    std::string key;
	    if (PyString_Check(PyTuple_GetItem(obj, 0))) {
		key = PyString_AsString(PyTuple_GetItem(obj, 0));
	    } else {
		PyErr_SetString(PyExc_TypeError,
				"expected string keys");
		return NULL;
	    }

            PyObject *val = PyTuple_GetItem(obj, 1);
	    if (PyString_Check(val)) {
	        std::string value = PyString_AsString(val);
		s.set(key, value);
		cout << "Set " << key << " to string `" << value << "'" << endl;
	    } else if (PyNumber_Check(val)) {
	        double value = PyFloat_AsDouble(PyNumber_Float(val));
		s.set(key, value);
		cout << "Set " << key << " to double `" << value << "'" << endl;
	    } else {
	        cout << "FOO" << endl;
		PyErr_SetString(PyExc_TypeError,
				"unexpected value type");
		return NULL;
	    }
	} else {
	    PyErr_SetString(PyExc_TypeError,
			    "expected tuple");
	    return NULL;
	}
    }
    $target = &s;
}

%typemap(python, out) om_termname_list {
    $target = PyList_New(0);
    if ($target == 0) {
	return NULL;
    }

    om_termname_list::const_iterator i = $source->begin();

    while (i!= $source->end()) {
        // FIXME: check return values (once we know what they should be)
        PyList_Append($target, PyString_FromString(i->c_str()));
	++i;
    }
    delete $source;
    $source = 0;
}

%typemap(python, in) const vector<string> &(vector<string> v){
    if (!PyList_Check($source)) {
        PyErr_SetString(PyExc_TypeError, "expected list");
        return NULL;
    }
    int numitems = PyList_Size($source);
    for (int i=0; i<numitems; ++i) {
        PyObject *obj = PyList_GetItem($source, i);
	if (PyString_Check(obj)) {
	    int len = PyString_Size(obj);
	    char *err = PyString_AsString(obj);
	    v.push_back(string(err, len));
	} else {
	    PyErr_SetString(PyExc_TypeError,
			    "expected list of strings");
	    return NULL;
	}
    }
    $target = &v;
}

%typedef PyObject *LangSpecificListType;

#define OMMSET_DID 0
#define OMMSET_WT 1
#define OMMSET_COLLAPSEKEY 2

#define OMESET_TNAME 0
#define OMESET_WT 1
%{
#define OMMSET_DID 0
#define OMMSET_WT 1
#define OMMSET_COLLAPSEKEY 2

#define OMESET_TNAME 0
#define OMESET_WT 1

PyObject *OmMSet_items_get(OmMSet *mset)
{
    PyObject *retval = PyList_New(0);
    if (retval == 0) {
	return NULL;
    }

    vector<OmMSetItem>::const_iterator i = mset->items.begin();
    while (i != mset->items.end()) {
        PyObject *t = PyTuple_New(3);

	PyTuple_SetItem(t, OMMSET_DID, PyInt_FromLong(i->did));
	PyTuple_SetItem(t, OMMSET_WT, PyFloat_FromDouble(i->wt));
	PyTuple_SetItem(t, OMMSET_COLLAPSEKEY, PyString_FromString(i->collapse_key.value.c_str()));

	PyList_Append(retval, t);
        ++i;
    }
    return retval;
}

PyObject *OmESet_items_get(OmESet *eset)
{
    PyObject *retval = PyList_New(0);
    if (retval == 0) {
	return NULL;
    }

    vector<OmESetItem>::const_iterator i = eset->items.begin();
    while (i != eset->items.end()) {
        PyObject *t = PyTuple_New(2);

	PyTuple_SetItem(t, 0, PyString_FromString((i->tname).c_str()));
	PyTuple_SetItem(t, 1, PyFloat_FromDouble(i->wt));

	PyList_Append(retval, t);
        ++i;
    }
    return retval;
}
%}

%typemap(python, memberout) PyObject *items {
    $target = PyList_New(0);
    if ($target == 0) {
	return NULL;
    }

    vector<OmMSetItem>::const_iterator i = $source.begin();
    while (i != $source.end()) {
        PyObject *t = PyTuple_New(3);

	PyTuple_SetItem(t, 0, PyInt_FromLong(i->did));
	PyTuple_SetItem(t, 1, PyFloat_FromDouble(i->wt));
	PyTuple_SetItem(t, 2, PyString_FromString(i->collapse_key.value.c_str()));

	PyList_Append($target, t);
        ++i;
    }
%}

%addmethods OmMSet {
    %readonly
    // access to the items array
    PyObject *items;

    // for comparison
    int __cmp__(const OmMSet &other) {
	if (self->docs_considered != other.docs_considered) {
	    return (self->docs_considered < other.docs_considered)? -1 : 1;
	} else if (self->max_possible != other.max_possible) {
	    return (self->max_possible < other.max_possible)? -1 : 1;
	} else if (self->items.size() != other.items.size()) {
	    return (self->items.size() < other.items.size())? -1 : 1;
	}

	for (int i=0; i<self->items.size(); ++i) {
	    if (self->items[i].wt != other.items[i].wt) {
		return (self->items[i].wt < other.items[i].wt)? -1 : 1;
	    } else if (self->items[i].did != other.items[i].did) {
		return (self->items[i].did < other.items[i].did)? -1 : 1;
	    }
	}
	return 0;
    }
    %readwrite
}

%apply LangSpecificListType items { PyObject *items }

%typemap(python, out) OmKey {
    $target = PyString_FromString(($source)->value.c_str());
    delete $source;
    $source = 0;
}

%typemap(python, out) OmData {
    $target = PyString_FromString(($source)->value.c_str());
    delete $source;
    $source = 0;
}

%addmethods OmESet {
    %readonly
    PyObject *items;
    %readwrite
}
