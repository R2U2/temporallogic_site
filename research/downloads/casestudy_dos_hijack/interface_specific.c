/*--------------------------------------------------------------
-- Title      : rtR2U2 draoneye Software
-- Project    : rtR2U2 <-> dragoneye SWHM
----------------------------------------------------------------
-- File       : interface_to_serialinterface.c
-- Author     : Patrick Moosbrugger
-- Company    : Nasa ARC-TI (SGT)
-- Last update: 2014-07-30
-- Platform   : <parallella board, tested on Ubuntu Headless>
----------------------------------------------------------------
-- Description: Interface definition between Autopilot and rtr2u2
---------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author        Description
-- <date>      <nr.>    <author>      <changes done>
--------------------------------------------------------------*/
#include <math.h>
#include "AP_Rtr2u2.h"
#include <stdbool.h>
#include "interface_to_serialinterface.h"

/* Autopilot data to the rtr2u2 interface */
void transmit_data_to_serialinterface(const struct rtR2U2_packet * pPacket, FILE *pCsvfd) {

FILE *pCsvfile;


	/* Get CSV file descriptor */
	pCsvfile=pCsvfd;

	add_variable_to_output(&pPacket->timestamp, ap_uint32_t, 0, 32, 0); 	 	/* timestap 33bit (32+1) */
	add_variable_to_output(&pPacket->current_loc_lat, ap_int32_t, 0, 32, 0);	/* Current Location Latitude in lat* 10**7  */
	add_variable_to_output(&pPacket->current_loc_lng, ap_int32_t, 0, 32, 0);
	add_variable_to_output(&pPacket->gps_num_sats, ap_uint8_t, 0, 8, 0); 		/* Number of visible satelites */
	add_variable_to_output(&pPacket->gps_lock_status, ap_uint8_t, 0, 8, 0);		/* Lock Status of the GPS */
	add_variable_to_output(&pPacket->ahrs_navekf_offset_north, ap_int8_t, 0, 8, 0); /* Navigation offset North */
	add_variable_to_output(&pPacket->ahrs_navekf_offset_east, ap_int8_t, 0, 8, 0); 	/* Navigation offset Eeast */
	add_variable_to_output(&pPacket->control_mode, ap_uint8_t, 0, 8, 0);			/* Mode of the Plane */
	add_variable_to_output(&pPacket->in_log_download, ap_uint8_t, 0, 8, 0);
	add_variable_to_output(&pPacket->mavpacket_id, ap_uint8_t, 0, 8, 0);			/* last Mavlink Packet ID */
	add_variable_to_output(&pPacket->mavpacket_long_cmd, ap_uint16_t, 0, 16, 0);	/* Command if mavpacket_id = MAVLINK_MSG_ID_COMMAND_LONG */
	add_variable_to_output(&pPacket->mavpacket_drop_cnt, ap_uint16_t, 0, 16, 0);	/* Number of illegal Mavlink Packets since last rtr2u2 transmission */
	add_variable_to_output(&pPacket->mavpacket_changemode_cnt, ap_uint8_t, 0, 8, 0);
	add_variable_to_output(&pPacket->mavpacket_calibration_cnt, ap_uint8_t, 0, 8, 0);
	add_variable_to_output(&pPacket->mavpacket_request_mission_list_cnt, ap_uint8_t, 0, 8, 0);
	add_variable_to_output(&pPacket->mavpacket_read_mission_item_cnt, ap_uint8_t, 0, 8, 0);
	add_variable_to_output(&pPacket->mavpacket_request_param_list_cnt, ap_uint8_t, 0, 8, 0);
	add_variable_to_output(&pPacket->mavpacket_read_param_list_cnt, ap_uint8_t, 0, 8, 0);
	add_variable_to_output(&pPacket->mavpacket_mission_clear_all_cnt, ap_uint8_t, 0, 8, 0);
	add_variable_to_output(&pPacket->mavpacket_mission_set_current_cnt, ap_uint8_t, 0, 8, 0);
	add_variable_to_output(&pPacket->mavpacket_store_new_mission_item_cnt, ap_uint8_t, 0, 8, 0);
	add_variable_to_output(&pPacket->mavpacket_set_param_cnt, ap_uint8_t, 0, 8, 0);
	add_variable_to_output(&pPacket->mavpacket_request_or_erase_log_cnt, ap_uint8_t, 0, 8, 0);
	add_variable_to_output(&pPacket->mavpacket_set_home_cnt, ap_uint8_t, 0, 8, 0);
	add_variable_to_output(&pPacket->num_of_mission_items, ap_uint8_t, 0, 8,1);

	/* Create a new Line in CSV File */
	if (pCsvfile!=NULL) {
		fputc('\n', pCsvfile);
	}

#endif

}





