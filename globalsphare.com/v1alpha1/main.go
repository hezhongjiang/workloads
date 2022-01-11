package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"strings"
)

type def struct {
	Source    string
	Name      string
	Ver       string
	ValuePath string
	YamlPath  string
	CuePath   string
	MetaPath  string
}

func main() {
	sql := ""
	workload := make([]def, 0)

	//type
	workload = append(workload, def{"workloadType", "webservice", "aam.globalsphare.com/v1alpha1", "workloadType/webservice.yaml", "", "", ""})
	workload = append(workload, def{"workloadType", "worker", "aam.globalsphare.com/v1alpha1", "workloadType/worker.yaml", "", "", ""})
	workload = append(workload, def{"workloadType", "mysql", "aam.globalsphare.com/v1alpha1", "workloadType/mysql.yaml", "", "", ""})
	workload = append(workload, def{"workloadType", "mysql-bare", "aam.globalsphare.com/v1alpha1", "workloadType/mysql-bare.yaml", "", "", ""})
	workload = append(workload, def{"workloadType", "redis", "aam.globalsphare.com/v1alpha1", "workloadType/redis.yaml", "", "", ""})
	workload = append(workload, def{"workloadType", "kafka", "aam.globalsphare.com/v1alpha1", "workloadType/kafka.yaml", "", "", ""})
	workload = append(workload, def{"workloadType", "rabbitmq", "aam.globalsphare.com/v1alpha1", "workloadType/rabbitmq.yaml", "", "", ""})
	workload = append(workload, def{"workloadType", "zookeeper", "aam.globalsphare.com/v1alpha1", "workloadType/zookeeper.yaml", "", "", ""})

	//vendor
	workload = append(workload, def{
		"workloadVendor",
		"webservice",
		"aam.globalsphare.com/v1alpha1",
		"workloadVendor/value/webservice.yaml",
		"workloadVendor/yaml/webservice.yaml",
		"workloadVendor/cue/webservice.cue",
		"workloadVendor/metadata/webservice.yaml",
	})
	workload = append(workload, def{
		"workloadVendor",
		"worker",
		"aam.globalsphare.com/v1alpha1",
		"workloadVendor/value/worker.yaml",
		"workloadVendor/yaml/worker.yaml",
		"workloadVendor/cue/worker.cue",
		"workloadVendor/metadata/worker.yaml",
	})
	workload = append(workload, def{
		"workloadVendor",
		"mysql",
		"aam.globalsphare.com/v1alpha1",
		"workloadVendor/value/mysql.yaml",
		"workloadVendor/yaml/mysql.yaml",
		"workloadVendor/cue/mysql.cue",
		"workloadVendor/metadata/mysql.yaml",
	})
	workload = append(workload, def{
		"workloadVendor",
		"mysql-bare",
		"aam.globalsphare.com/v1alpha1",
		"workloadVendor/value/mysql-bare.yaml",
		"workloadVendor/yaml/mysql-bare.yaml",
		"workloadVendor/cue/mysql-bare.cue",
		"workloadVendor/metadata/mysql-bare.yaml",
	})
	workload = append(workload, def{
		"workloadVendor",
		"redis",
		"aam.globalsphare.com/v1alpha1",
		"workloadVendor/value/redis.yaml",
		"workloadVendor/yaml/redis.yaml",
		"workloadVendor/cue/redis.cue",
		"workloadVendor/metadata/redis.yaml",
	})
	workload = append(workload, def{
		"workloadVendor",
		"kafka",
		"aam.globalsphare.com/v1alpha1",
		"workloadVendor/value/kafka.yaml",
		"workloadVendor/yaml/kafka.yaml",
		"workloadVendor/cue/kafka.cue",
		"workloadVendor/metadata/kafka.yaml",
	})
	workload = append(workload, def{
		"workloadVendor",
		"rabbitmq3",
		"aam.globalsphare.com/v1alpha1",
		"workloadVendor/value/rabbitmq3.yaml",
		"workloadVendor/yaml/rabbitmq3.yaml",
		"workloadVendor/cue/rabbitmq3.cue",
		"workloadVendor/metadata/rabbitmq3.yaml",
	})
	workload = append(workload, def{
		"workloadVendor",
		"rabbitmq3-ceph",
		"aam.globalsphare.com/v1alpha1",
		"workloadVendor/value/rabbitmq3-ceph.yaml",
		"workloadVendor/yaml/rabbitmq3-ceph.yaml",
		"workloadVendor/cue/rabbitmq3-ceph.cue",
		"workloadVendor/metadata/rabbitmq3-ceph.yaml",
	})
	workload = append(workload, def{
		"workloadVendor",
		"rabbitmq3-plugins",
		"aam.globalsphare.com/v1alpha1",
		"workloadVendor/value/rabbitmq3-plugins.yaml",
		"workloadVendor/yaml/rabbitmq3-plugins.yaml",
		"workloadVendor/cue/rabbitmq3-plugins.cue",
		"workloadVendor/metadata/rabbitmq3-plugins.yaml",
	})
	workload = append(workload, def{
		"workloadVendor",
		"rabbitmq3-plugins-ceph",
		"aam.globalsphare.com/v1alpha1",
		"workloadVendor/value/rabbitmq3-plugins-ceph.yaml",
		"workloadVendor/yaml/rabbitmq3-plugins-ceph.yaml",
		"workloadVendor/cue/rabbitmq3-plugins-ceph.cue",
		"workloadVendor/metadata/rabbitmq3-plugins-ceph.yaml",
	})
	workload = append(workload, def{
		"workloadVendor",
		"zookeeper",
		"aam.globalsphare.com/v1alpha1",
		"workloadVendor/value/zookeeper.yaml",
		"workloadVendor/yaml/zookeeper.yaml",
		"workloadVendor/cue/zookeeper.cue",
		"workloadVendor/metadata/zookeeper.yaml",
	})
	//trait
	workload = append(workload, def{
		"trait",
		"ingress",
		"aam.globalsphare.com/v1alpha1",
		"trait/ingress.yaml",
		"",
		"",
		"",
	})

	for _, v := range workload {
		tableName := ""
		if v.Source == "workloadType" {
			tableName = "t_type"
		} else if v.Source == "workloadVendor" {
			tableName = "t_vendor"
		} else {
			tableName = "t_trait"
		}
		//获取value
		value_str := ""
		if v.ValuePath != "" {
			b, err := ioutil.ReadFile(v.ValuePath)
			if err != nil {
				fmt.Println(err)
				return
			}
			value, err := json.Marshal(string(b))
			if err != nil {
				fmt.Println(err)
				return
			}
			value_str = string(value)
		}

		//yaml
		yaml_str := ""
		if v.YamlPath != "" {
			yaml_b, err := ioutil.ReadFile(v.YamlPath)
			if err != nil {
				fmt.Println(err)
				return
			}
			yaml_b2, err := json.Marshal(string(yaml_b))
			if err != nil {
				fmt.Println(err)
				return
			}
			yaml_str = string(yaml_b2)
		}
		//cue
		cue_str := ""
		if v.CuePath != "" {
			cue_b, err := ioutil.ReadFile(v.CuePath)
			if err != nil {
				fmt.Println(err)
				return
			}
			cue, err := json.Marshal(string(cue_b))
			if err != nil {
				fmt.Println(err)
				return
			}
			cue_str = string(cue)
		}

		//metadata
		meta_str := ""
		if v.MetaPath != "" {
			meta_b, err := ioutil.ReadFile(v.MetaPath)
			if err != nil {
				fmt.Println(err)
				return
			}
			meta, err := json.Marshal(string(meta_b))
			if err != nil {
				fmt.Println(err)
				return
			}
			meta_str = string(meta)
		}

		if tableName == "t_vendor" {
			sql += fmt.Sprintf("insert into %s(`name`, `yaml`, `cue`, `metadata`, `ver`,`value`)values(\"%s\", %s, %s,%s,\"%s\",%s);\n",
				tableName, v.Name, yaml_str, cue_str, meta_str, v.Ver, value_str)
		} else {
			sql += fmt.Sprintf("insert into %s(`name`, `ver`,`value`)values(\"%s\", \"%s\", %s);\n", tableName, v.Name, v.Ver, value_str)
		}
		//insert into t_vendor(`name`, `yaml`, `cue`, `metadata`, `ver`,`value`)values("webservice", "webservice", "webservice", "name: webservice",
		//sql += title + fmt.Sprintf("insert into %s(`name`, `ver`,`value`)values(\"%s\", \"%s\", %s);\n",tableName, v.Name, v.Ver, string(s))
	}
	sql = strings.ReplaceAll(sql, "\\u003e", ">")
	ioutil.WriteFile("workloads.sql", []byte(sql), 0644)
}
