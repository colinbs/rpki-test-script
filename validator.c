#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "rtrlib/rtrlib.h"
#include "rtrlib/pfx/lpfst/lpfst-pfx.h"

int main(int argc, char *argv[]) {

    if(argc != 5) {
        printf("Usage: ./validator formattedRIBDump outputFile host port\n");
        return 1;
    }
	
	// The parameters required to validate
	// a route with rtr_mgr_validate are as
	// followed:
	// struct rtr_mgr_config*
	// const uint32_t
	// const struct lrtr_ip_addr*
	// const uint8_t
	// 
	// It then returns a enum state depending on
	// whether it succeeded or failed.
	
	// I will skip the ssh sockets in this program
	// because I have no valid examples for hostkey
	// and private key.
	
	// First create tcp sockets to create the groups
	// needed for rtr_mgr_init
	
	struct tr_socket tr_tcp;
	/*char tcp_host[] = "rpki-validator.realmv6.org";*/
    char *tcp_host = argv[3];
	char *tcp_port = argv[4];

	// Here is the configuration for the first socket.
	struct tr_tcp_config tcp_config = {
		tcp_host,
		tcp_port,
		NULL
	};
	tr_tcp_init(&tcp_config, &tr_tcp);

	// Create a second socket and configuration.
	// Don't do this for now.
	//struct tr_socket tr_tcp2;
	//char tcp2_host[] = "localhost";
	//char tcp2_port[] = "8282";

	//struct tr_tcp_config tcp_config2 = {
		//tcp2_host,
		//tcp2_port,
		//NULL
	//};

	// Initialize the second tcp socket.
	//tr_tcp_init(&tcp_config2, &tr_tcp2);

	// Create rtr sockets and associate them with the tcp sockets. K.
	struct rtr_socket rtr_tcp;
	rtr_tcp.tr_socket = &tr_tcp;
	//struct rtr_socket rtr_tcp2;
	//rtr_tcp2.tr_socket = &tr_tcp2;

	// I will create the rtr_mrg_group array with only one element
	// since I skipped the ssh socket.
	struct rtr_mgr_group groups[1];

	groups[0].sockets = malloc(1 * sizeof(struct rtr_socket*));
	groups[0].sockets_len = 1;
	groups[0].sockets[0] = &rtr_tcp;
	//groups[0].sockets[1] = &rtr_tcp2;
	groups[0].preference = 1;

	// Now it's getting interesting, yet confusing.
	// Initialize all rtr_sockets in the server pool with the same settings.
	struct rtr_mgr_config *conf;
	// To be honest, I did not fully understand the initialization values.
	// I'm working on it, though!
	int ret = rtr_mgr_init(&conf, groups, 1, 30, 600, 600, NULL, NULL, NULL, NULL);

	rtr_mgr_start(conf);
	
	// This does not return true, no matter how long I wait.
	while(!rtr_mgr_conf_in_sync(conf)) {
		sleep(1);
	}
	
	FILE *fp;

	// This is the output file.
	FILE *fvalid;

	char csv_line[100] = {0};
    
	fp = fopen(argv[1], "r");

	fvalid = fopen(argv[2], "w");

	// Check whether all files were opened.
	if(fp == NULL || fvalid == NULL) {
		// Close and stop sockets here.
		rtr_mgr_stop(conf);
		rtr_mgr_free(conf);
		free(groups[0].sockets);

		// Close all files.
		fclose(fp);
		fclose(fvalid);

		// Exit program here.
		perror("Error while opening one of the files.\n");
		exit(EXIT_FAILURE);
	}

	// Get line for line from the csv file.
	while(fgets(csv_line, 100, fp) != NULL) {
		// The values fetched from each line are stored here.
		char ip[128] = {0};
		char len[4] = {0};
		char asn[32] = {0};

		// prefix and asn need to be converted to integers later.
		int len_i;
		int asn_i;

		int i = 0;
		int j;
		// Get the prefix here.
        for(j = 0; csv_line[i] != '/'; i++, j++) {
			ip[j] = csv_line[i];
		}
		// Increment i again to skip the "/".
		i++;
		for(j = 0; csv_line[i] != ' '; i++, j++) {
			len[j] = csv_line[i];
		}
		// Increment i again to skip the " ".
		i++;
		// Get the asn here.
		for(j = 0; csv_line[i] != '\n'; i++, j++) {
			asn[j] = csv_line[i];
		}
		// Convert len and asn to int here.
		len_i = atoi(len);
		asn_i = atoi(asn);
		
		// validate route here!
		struct lrtr_ip_addr pref;
		lrtr_ip_str_to_addr(ip, &pref);

        struct pfx_record *reason = NULL;
        unsigned int reason_len = 0;

		enum pfxv_state result;
        pfx_table_validate_r(groups[0].sockets[0]->pfx_table, &reason, &reason_len, asn_i, &pref, len_i, &result);
		//rtr_mgr_validate(conf, asn_i, &pref, len_i, &result);
        
        // TODO: unmanaged code!
        if (reason && (reason_len > 0)) {
            unsigned int i;

            for (i = 0; i < reason_len; i++) {
                char tmp[100];

                lrtr_ip_addr_to_str(&reason[i].prefix, tmp, sizeof(tmp));
                printf("%u %s %u %u",
                    reason[i].asn, tmp,
                    reason[i].min_len,
                    reason[i].max_len
                );
                if ((i + 1) < reason_len)
                    printf(",");
            }
        }

		// Write the routes to the corresponding files.
		if(result == BGP_PFXV_STATE_VALID) {
			fprintf(fvalid, "%s/%d %s \"Valid\"\n", ip, len_i, asn);
		} else if(result == BGP_PFXV_STATE_NOT_FOUND) {
			fprintf(fvalid, "%s/%d %s \"NotFound\"\n", ip, len_i, asn);
		} else if(result == BGP_PFXV_STATE_INVALID) {
			fprintf(fvalid, "%s/%d %s \"Invalid\"\n", ip, len_i, asn);
		}
	}
	
	// Close the file access.
	fclose(fp);
	fclose(fvalid);

	// Stop and free stuff.
	rtr_mgr_stop(conf);
	rtr_mgr_free(conf);
	free(groups[0].sockets);

	return 0;
}
