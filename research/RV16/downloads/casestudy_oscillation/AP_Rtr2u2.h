/*--------------------------------------------------------------
-- Title      : rtR2U2

-- Project    : rtR2U2 <-> dragoneye SWHM
----------------------------------------------------------------
-- File       : rtR2U2.h
-- Author     : Patrick Moosbrugger
-- Company    : Nasa ARC-TI (SGT)
-- Last update: 2014-07-30
-- Platform   : <dragoneye (Ardupilot 3.1.2), arm-gcc>
----------------------------------------------------------------
-- Description: Definition of the Inputvector for the rtR2U2
				Framework
----------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author        Description
-- <date>      <nr.>    <author>      <changes done>
--------------------------------------------------------------*/

#ifndef _AP_RTR2U2_H_
#define _AP_RTR2U2_H_
#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

/* Enable building for STIL */
#define PAMO_SITL

/* Enable Instrumentation if Macro RTR2U2_EN is defined */
#define RTR2U2_EN
#ifdef RTR2U2_EN

#define HEADER_VERIFICATION_START (0x5A5A)
#define HEADER_PACKET_START (0xA5A5)
#define RTR2U2_PACKET_VERSION (0x01)

/* Choose if Instrumentation optimized for speed or Memory Consumption, (Commented=Speed, Uncommented=Memory) */
#define RTR2U_OPTIMIZE_MEMORY

/****************************************************
 * Choose the Setup you want to use for Verification
 ****************************************************/
#define RTR2U2_LOW_LEVEL_OS
#define RTR2U2_LOW_LEVEL_SENS_COMM
/* #define RTR2U2_LOW_LEVEL_ACTUATOR_COMM */
#define RTR2U2_COMMAND_COMM
/* #define RTR2U2_INTERNAL_CALCULATIONS */
#define RTR2U2_BEHAVIORAL
/* #define RTR2U2_BATTERY */

/* define custom signal names */

 enum rtr2u2_signal_type {
	s_header_verification_start, /* header of the packet */
	s_header_packet_start,
	s_timestamp,			/* Current Timestamp of Packet - possible to observe up to 71 minutes in
							   microsecond granularity */
#ifdef RTR2U2_LOW_LEVEL_OS
	s_boot_detected,		/* 1 for 1 transmission when a new boot is detected */
	s_clear_boot_detected,	/* this is to clear the s_reboot_detected flag after the first transmission
							   updated in monitoring() task AFTER the transmission */

	s_tick_counter,			/* the most recent scheduler tick counter value
							   updated in scheduler.tick() Method */
	s_free_memory,			/* Returns how much free memory is available
							   updated in monitoring method BEFORE the transmission */
#if 0
	s_num_of_uart_isr_tx,	/* Number, how often the UART TX ISR is called
							   updated in UART TX ISR
							   Note: 32 bit counter @115kbps Overflow occurs (Worst-Case)
							   at around (2^32)*70us = ~5010 Minutes*/

	s_num_of_uart_isr_rx,   /* Number, how often the UART RX ISR is called
							   updated in UART RX ISR */
#endif
	s_num_of_scheduler_tick_overflow,	/* counter how often the scheduler tick had an overflow
										   Note: Every overflow is detected, but s_tick_counter might be
										   already a couple of ticks further since the monitoring task runs
										   at low priority	updated during indirectly throug s_tick_sounter
										   signal in scheduler.tick Method */
	s_task_i_num_runable,	/* Number how often the Task with id i is runnable
									   updated in scheduler.run */
	s_task_i_num_run,		/* Number how often the Task with id i was executed */
	s_all_tasks_zero_counters,		/* Signal to clear all counters that have to be zeroed after a transmission */
	s_task_i_num_overrun,	/* Number how often the Task with id ioverrun the allowed time
									   updated in scheduler.run */

	s_task_i_slipped,  		/* Number how often the Task with id iis slipped by the scheduler
									   updated in scheduler.run */
	s_task_i_delay,  		/* Maximum Delay (in Scheduler Ticks) a Task had
									   updated in scheduler.run */
	s_failsafe_cnt,			/* How often did we RE-enter sw-failsafe state */
	s_wipe_eeprom_cnt,		/* How often the EEPROM has been deleted (Reset after every packet) */
	s_reset_eeprom_cnts,	/* Reset the eeprom monitor counters */
	s_write_eeprom_param_sect_cnt, /* Counter how often we wrote to the param section of the eeprom since last transmission */
#endif
#ifdef RTR2U2_LOW_LEVEL_SENS_COMM
	s_compass_last_update,		/* last update compass */
	// s_compass_no_i2c_sem_cnt,	/* Counter how often we did not get semaphore */
	s_baro_last_update,			/* last update barometer */
	// s_baro_no_spi0_sem_cnt,		/* Counter how often we did not get semaphore */
	s_gps_lock_status,			/* GPS Lock Status */
    	s_gps_last_fix_time,		/* last gps fix (timestamp) in ms */
   	 s_ins_last_sample_time,		/* Last Sample time of the Inertial Sensor in us */
	// s_gps_uart_..
    	s_spi_blocked_sem_cnt,		/* Counter how often failed to get SPI Semaphore */
    	s_spi_timeout_sem_cnt,		/* Counter how often a Blocking Semaphore Timeout was reached */
    	s_spi_wrong_give_sem_cnt,	/* Counter how often a Semaphore was tried to give without having it */
	// s_airspeed_last_update,		/* last update airspeed */
	// s_i2c_lockup_count,
	// s_i2c_timeout,
#endif  /* RTR2U2_LOW_LEVEL_SENS_COMM */
#ifdef RTR2U2_COMMAND_COMM
   	s_last_heartbeat,		/* the time when the last HEARTBEAT message arrived from a GCS in ms */
	s_in_log_download,
    	s_reset_mavpacket_cnts,	/* Signal to clear the mavpacket counters */
    	s_mavpacket_id,
    	s_mavpacket_long_cmd,
	// s_mavpacket_changemode_cnt, /* Change mode request detected */
	// s_mavpacket_drop_cnt,	/* Number of illegal Mavlink Packets since last rtr2u2 transmission */
	// s_mavpacket_calibration,
	// s_mavpacket_request_mission_list,
	// s_mavpacket_read_mission_item,
	// s_mavpacket_request_param_list,
	// s_mavpacket_read_param_list,
	// s_mavpacket_mission_clear_all,
	// s_mavpacket_mission_set_current,
	// s_mavpacket_store_new_mission_item,
	// s_mavpacket_set_param,
	// s_mavpacket_request_or_erase_log,
	// s_mavpacket_set_home,
	// s_num_of_mission_items,
#endif /* RTR2U2_COMMAND_COMM */
#ifdef RTR2U2_BEHAVIORAL  /* RTR2U2_BEHAVIORAL */
	/* Note, some signals could be consolidated to a single one if they're derived from
	 * the same source, e.g. current_loc struct ...
	 * This implementation splits them to have more flexibility
	 * the cost is more overhead due to a higher number
	 * of context switches in the monitoring tasks
	 */
	s_current_loc_alt,		/* Current Location Altitude */
	s_current_loc_lat,		/* Current Location Latitude */
	s_current_loc_lng,		/* Current Location Longitude */
    	s_gps_num_sats,         /* Number of visible satelites */
    	s_gps_ground_speed_cm,	/* GPS Ground speed in cm/s */
    	s_gps_alt,
    	s_airspeed_m,			/* airspeed in m/s */
	// s_baro_pressure,
	// s_baro_temperature,
	s_baro_climb_rate,		/* Barometer climb rate in m/s (positiv=going up) */
	s_baro_alt,				/* Barometric altitude */
	s_home_alt,				/* Altitude of the home location */
	s_home_lat,				/* Latitude of the home location */
	s_home_lng,				/* Longitude of the home location */
	s_next_wp_alt,			/* Altitude of the next Waypoint */
	s_next_wp_lat,			/* Latitude of the next Waypoint */
	s_next_wp_lng,			/* Longitude of the next Waypoint */
	s_control_mode,			/* Mode of the Plane */
	s_ins_accel_x,			/* IMU X Acceleration */
	s_ins_accel_y,			/* IMU Y Acceleration */
	s_ins_accel_z,			/* IMU Z Acceleration */
	s_ahrs_pitch,			/* AHRS.pitch */
// 	s_ahrs_navekf_offset, 	/* Navigation offset North and East*/
#endif
#ifdef RTR2U2_BATTERY
	s_battery_voltage,		/* Battery Voltage */
	s_battery_low_voltage,	/* Battery Low Voltage (Parameter */
	/* Currently only the Voltage of the Battery is monitored on the dragoneye,
	 * Future implementations could also use:
	 * s_battery_exhausted,
	 * s_battery_current_amps,
	 */
#endif
	s_update_skipped, 		/* Counter for missed updates during transmission was in progress */
	s_packet_skipped,		/* Counter for not sent rtr2u2 packets */
	s_temp1,				/* Can be used to transmit data for debugging purposes */
	s_temp2					/* Can be used to transmit data for debugging purposes
							   Currently, holds version number if verification_start packet */
};



/****************************************************
 * packet definition for current selected setup
 ****************************************************/

 	struct rtr2u2_task_data {
 		uint32_t runable_cnt;
		uint8_t run_cnt;			/* Counter is reseted after every transmission */
 		uint8_t overrun_cnt;
 		uint8_t slipped_cnt;
 		uint8_t max_delay;
 		float mean_delay;
 	} __attribute__ ((packed)) ;

/* Packet to transmit
 * NOTE: Must not be greater then 256 Byte since
 * UART Driver Buffer is limited to this size
 * Note when adding new values: The atChecker of the Framework
 * expects only signed types. Conversions can be done	 in the
 * receiving application of the parallella.
 */
 struct rtR2U2_packet {								//TOTAL BYTES
 	uint16_t header;
 	uint32_t timestamp;	/* Current Timestamp of Packet - possible to observe up to 71 minutes in microsecond granularity */
#ifdef RTR2U2_LOW_LEVEL_OS

	uint8_t boot_detected;
	uint8_t num_of_scheduler_tick_overflow;
	uint16_t tick_counter;
	uint32_t free_memory;
//	uint32_t num_of_uart_isr_tx;
//	uint32_t num_of_uart_isr_rx;
	rtr2u2_task_data read_radio;
//	rtr2u2_task_data check_short_failsafe;
	rtr2u2_task_data ahrs_update;
	rtr2u2_task_data update_speed_height;
//	rtr2u2_task_data update_flight_mode;
//	rtr2u2_task_data stabilize;
//	rtr2u2_task_data set_servos;
//	rtr2ugps_alt2_task_data read_control_switch;
	rtr2u2_task_data gcs_retry_deferred;
	rtr2u2_task_data update_GPS;
	rtr2u2_task_data navigate;
//	rtr2u2_task_data update_compass;
//	rtr2u2_task_data read_airspeed;
//	rtr2u2_task_data update_alt;
//	rtr2u2_task_data calc_altitude_error;
//	rtr2u2_task_data update_commands;
//	rtr2u2_task_data obc_fs_check;
	rtr2u2_task_data gcs_update;
	rtr2u2_task_data gcs_data_stream_send;
//	rtr2u2_task_data update_mount;
//	rtr2u2_task_data update_events;
//	rtr2u2_task_data check_usb_mux;
//	rtr2u2_task_data read_battery;
//	rtr2u2_task_data compass_accumulate;
//	rtr2u2_task_data barometer_accumulate;
	rtr2u2_task_data update_notify;
//	rtr2u2_task_data one_second_loop;
//	rtr2u2_task_data check_long_failsafe;
//	rtr2u2_task_data airspeed_ratio_update;
//	rtr2u2_task_data update_logging;
//	rtr2u2_task_data read_receiver_rssi;
	rtr2u2_task_data monitoring;
	uint8_t failsafe_cnt;				/* How often did we RE-enter sw-failsafe state */
	uint8_t wipe_eeprom_cnt;			/* Counter for eeprom wipe commands (resetted after transmission) */
	uint8_t write_eeprom_param_sect_cnt;/* Counter how often we wrote to the EEPROM Parameter section since last transmission */
#endif  /* RTR2U2_LOW_LEVEL_OS */
#ifdef RTR2U2_LOW_LEVEL_SENS_COMM
    uint32_t compass_last_update;   	/* last update (timestamp) compass in us */
    uint32_t baro_last_update;			/* last update (timestamp) barometer in ms */
    uint8_t gps_lock_status;			/* Lock Status of the GPS
										   NO_GPS = 0,         No GPS connected/detected
										   NO_FIX = 1,         Receiving valid GPS messages but no lock
										   GPS_OK_FIX_2D = 2,  Receiving valid messages and 2D lock
										   GPS_OK_FIX_3D = 3   Receiving valid messages and 3D lock
										   Note, actually the status is of type enum GPS_Status
										   (see gps.h) However, we use a uint8 to simplyfy
										   The interface to the parallella and will use the
										   "hard-coded" values as defined in the defines.h for
										   specifying verification properties */
    uint32_t gps_last_fix_time;			/* last gps fix (timestamp) in ms */
    uint32_t ins_last_sample_time;		/* Last Sample time of the Inertial Sensor in us */
#if 0
    uint16_t spi0_blocked_sem_cnt;		/* Counter how often failed to get SPI Semaphore */
    uint16_t spi0_timeout_sem_cnt;		/* Counter how often a Blocking Semaphore Timeout was reached */
    uint16_t spi0_wrong_give_sem_cnt;	/* Counter how often a Semaphore was tried to give without having it */
#endif
#endif /* RTR2U2_LOW_LEVEL_SENS_COMM */

#ifdef RTR2U2_COMMAND_COMM
    uint32_t last_heartbeat;			/* the time when the last HEARTBEAT message arrived from a GCS in ms */
    uint8_t in_log_download;			/* has a download of a logfile started ?*/
    uint8_t mavpacket_id;				/* last Mavlink Packet ID */
    uint16_t mavpacket_long_cmd;		/* Command if mavpacket_id = MAVLINK_MSG_ID_COMMAND_LONG */
//  uint16_t mavpacket_drop_cnt;		/* Number of illegal Mavlink Packets since last rtr2u2 transmission */
//  uint8_t mavpacket_changemode_cnt; 	/* Change mode request detected */
//  uint8_t	mavpacket_calibration_cnt;			/* Number of MAV_CMD_PREFLIGHT_CALIBRATION mavpackets since the last rtr2u2 transmission */
//  uint8_t	mavpacket_request_mission_list_cnt; /* Number of MAVLINK_MSG_ID_MISSION_REQUEST_LIST mavpackets since the last rtr2u2 transmission */
//  uint8_t mavpacket_read_mission_item_cnt; 	/* Number of MAVLINK_MSG_ID_MISSION_REQUEST mavpackets since the last rtr2u2 transmission */
//  uint8_t mavpacket_request_param_list_cnt; 	/* Number of MAVLINK_MSG_ID_PARAM_REQUEST_LIST mavpackets since the last rtr2u2 transmission */
//  uint8_t mavpacket_read_param_list_cnt; 		/* Number of MAVLINK_MSG_ID_PARAM_REQUEST_READ mavpackets since the last rtr2u2 transmission */
//  uint8_t mavpacket_mission_clear_all_cnt; 	/* Number of MAVLINK_MSG_ID_MISSION_CLEAR_ALL mavpackets since the last rtr2u2 transmission */
//  uint8_t mavpacket_mission_set_current_cnt;  /* Number of MAVLINK_MSG_ID_MISSION_SET_CURRENT mavpackets since the last rtr2u2 transmission */
//  uint8_t mavpacket_store_new_mission_item_cnt; /* Number of  mavpackets since the last rtr2u2 transmission */
//  uint8_t mavpacket_set_param_cnt; 			/* Number of  mavpackets since the last rtr2u2 transmission */
//  uint8_t mavpacket_request_or_erase_log_cnt; /* Number of  mavpackets since the last rtr2u2 transmission */
//  uint8_t mavpacket_set_home_cnt;				/* Number of requests to change home location */
//  uint8_t num_of_mission_items;

#endif /* RTR2U2_COMMAND_COMM */

#ifdef RTR2U2_BEHAVIORAL  /* RTR2U2_BEHAVIORAL */
    int32_t current_loc_alt;	    /* Current Location Altitude in cm*/
    int32_t current_loc_lat;	    /* Current Location Latitude in lat* 10**7  */
    int32_t current_loc_lng;	    /* Current Location Longitude in lng* 10**7 */
    uint8_t gps_num_sats;           /* Number of visible satelites */
    uint32_t gps_ground_speed_cm;   /* GPS Ground Speed in cm/s */
    uint32_t gps_alt;
    float airspeed_m;		/* Airspeed in m/s */
    int32_t baro_alt;		/* Barometric Altitude in cm */
    float baro_climb_rate;      /* Barometer climb rate in m/s (positiv=going up) */
    int32_t home_alt;		/* Altitude of the home location in cm */
    int32_t home_lat;		/* Latitude of the home location in lat* 10**7 */
    int32_t home_lng;		/* Longitude of the home location in lng* 10**7 */
    int32_t next_wp_alt;	/* Altitude of the next Waypoint in cm */
    int32_t next_wp_lat;	/* Latitude of the next Waypoint in lat* 10**7 */
    int32_t next_wp_lng;	/* Longitude of the next Waypoint in lng* 10**7 */
    uint8_t control_mode; 	/* Mode of the Plane
									   Note, actually the control mode is of type enum FlightMode
									   (see ../../defines.h) However, we use a uint8 to simplyfy
									   The interface to the parallella and will use the
									   "hard-coded" values as defined in the defines.h for
									   specifying verification properties */
     float ins_accel_x; 	/* IMU x acceleration */
     float ins_accel_y;	 	/* IMU y acceleration */
     float ins_accel_z;		/* IMU z acceleration */
     int16_t ahrs_pitch;	/* AHRS.pitch */
//     int8_t ahrs_navekf_offset_north; /* Navigation offset North */
//     int8_t ahrs_navekf_offset_east;  /* Navigation offset Eeast */
#endif
#ifdef RTR2U2_BATTERY
	float battery_voltage;			/* Battery Voltage */
	float battery_low_voltage;		/* Battery Log Voltage (Parameter) */
#endif
	uint32_t temp1;
	uint32_t temp2;		/* Can be used to transmit data for debugging purposes,
				* currently, holds version number if verification_start packet */
	uint16_t num_of_updates_skipped;
	uint16_t num_of_packets_skipped;
	uint32_t crc32;
} __attribute__ ((packed)) ;


 /* Global Buffer to store the rtR2U2 Atomic */
 extern struct rtR2U2_packet rtr2u2_at_buffer_current;
 extern struct rtR2U2_packet rtr2u2_at_buffer_last;

#ifdef RTR2U2_LOW_LEVEL_OS

struct rtr2u2_task_map_entry {
	rtr2u2_task_data *pCurrent_data;
	rtr2u2_task_data *pLast_data;
 };

/* Used To create the rtr2u2_map and size cross-check when map is accessed */
#define RTR2U2_TASK_MAP_SIZE 36 /*(equals number of tasks)*/

/* Task ID from scheduler to corresponding Signals mapper */
/* Set _current and _last NULL if Task shall not be monitored */
static const rtr2u2_task_map_entry rtr2u2_task_map[RTR2U2_TASK_MAP_SIZE] = {
/*0*/  { &rtr2u2_at_buffer_current.read_radio, 				&rtr2u2_at_buffer_last.read_radio 			}, //read_radio
/*1*/  { NULL, NULL }, //check_short_failsafe
/*2*/  { &rtr2u2_at_buffer_current.ahrs_update, 			&rtr2u2_at_buffer_last.ahrs_update			}, //ahrs_update
/*3*/  { &rtr2u2_at_buffer_current.update_speed_height, 	&rtr2u2_at_buffer_last.update_speed_height  }, //update_speed_height
/*4*/  { NULL, NULL	}, //update_flight_mode
/*5*/  { NULL, NULL }, //stabilize
/*6*/  { NULL, NULL },
/*7*/  { NULL, NULL	}, //read_control_switch
/*8*/  { &rtr2u2_at_buffer_current.gcs_retry_deferred, 		&rtr2u2_at_buffer_last.gcs_retry_deferred 	},  //gcs_retry_deferred
/*9*/  { &rtr2u2_at_buffer_current.update_GPS, 				&rtr2u2_at_buffer_last.update_GPS 			}, //update_GPS
/*10*/ { &rtr2u2_at_buffer_current.navigate, 				&rtr2u2_at_buffer_last.navigate 			}, //navigate
/*11*/ { NULL, NULL	}, //update_compass
/*12*/ { NULL, NULL	}, //read_airspeed
/*13*/ { NULL, NULL }, //update_alt
/*14*/ { NULL, NULL }, //calc_altitude_error
/*15*/ { NULL, NULL }, //update_commands
/*16*/ { NULL, NULL }, //obc_fs_check
/*17*/ { &rtr2u2_at_buffer_current.gcs_update, 				&rtr2u2_at_buffer_last.gcs_update 			}, //gcs_update
/*18*/ { &rtr2u2_at_buffer_current.gcs_data_stream_send, 	&rtr2u2_at_buffer_last.gcs_data_stream_send }, //gcs_data_stream_send
/*19*/ { NULL, NULL }, //update_mount
/*20*/ { NULL, NULL }, //update_events
/*21*/ { NULL, NULL }, //check_usb_mux
/*22*/ { NULL, NULL }, //read_battery
/*23*/ { NULL, NULL }, //compass_accumulate
/*24*/ { NULL, NULL }, //barometer_accumulate
/*25*/ { &rtr2u2_at_buffer_current.update_notify, 			&rtr2u2_at_buffer_last.update_notify 		}, //update_notify
/*26*/ { NULL, NULL }, //one_second_loop
/*27*/ { NULL, NULL }, //check_long_failsafe
/*28*/ { NULL, NULL }, //airspeed_ratio_update
/*29*/ { NULL, NULL }, //update_logging
/*30*/ { NULL, NULL }, //read_receiver_rssi
{ NULL, NULL },
{ NULL, NULL },
{ NULL, NULL },
{ NULL, NULL },
/*31*/ { &rtr2u2_at_buffer_current.monitoring, 				&rtr2u2_at_buffer_last.monitoring			} //monitoring
};


/* All Tasks Setup */
#if 0
static const rtr2u2_task_map_entry rtr2u2_task_map[RTR2U2_TASK_MAP_SIZE] = {
/*0*/   { &rtr2u2_at_buffer_current.read_radio, 			&rtr2u2_at_buffer_last.read_radio 				},
/*1*/   { &rtr2u2_at_buffer_current.check_short_failsafe, 	&rtr2u2_at_buffer_last.check_short_failsafe 	},
/*2*/   { &rtr2u2_at_buffer_current.ahrs_update,			&rtr2u2_at_buffer_last.ahrs_update				},
/*3*/   { &rtr2u2_at_buffer_current.update_speed_height,   	&rtr2u2_at_buffer_last.update_speed_height		},
/*4*/   { &rtr2u2_at_buffer_current.update_flight_mode,    	&rtr2u2_at_buffer_last.update_flight_mode		},
/*5*/   { &rtr2u2_at_buffer_current.stabilize	,    		&rtr2u2_at_buffer_last.stabilize				},
/*6*/   { &rtr2u2_at_buffer_current.set_servos,    			&rtr2u2_at_buffer_last.set_servos				},
/*7*/   { &rtr2u2_at_buffer_current.read_control_switch,    &rtr2u2_at_buffer_last.read_control_switch		},
/*8*/   { &rtr2u2_at_buffer_current.gcs_retry_deferred,    	&rtr2u2_at_buffer_last.gcs_retry_deferred		},
/*9*/   { &rtr2u2_at_buffer_current.update_GPS,    			&rtr2u2_at_buffer_last.update_GPS				},
/*10*/  { &rtr2u2_at_buffer_current.navigate,    			&rtr2u2_at_buffer_last.navigate					},
/*11*/  { &rtr2u2_at_buffer_current.update_compass,    		&rtr2u2_at_buffer_last.update_compass			},
/*12*/  { &rtr2u2_at_buffer_current.read_airspeed,   		&rtr2u2_at_buffer_last.read_airspeed			},
/*13*/  { &rtr2u2_at_buffer_current.update_alt,    			&rtr2u2_at_buffer_last.update_alt				},
/*14*/  { &rtr2u2_at_buffer_current.calc_altitude_error,    &rtr2u2_at_buffer_last.calc_altitude_error		},
/*15*/  { &rtr2u2_at_buffer_current.update_commands,   		&rtr2u2_at_buffer_last.update_commands			},
/*16*/  { &rtr2u2_at_buffer_current.obc_fs_check,    		&rtr2u2_at_buffer_last.obc_fs_check				},
/*17*/  { &rtr2u2_at_buffer_current.gcs_update,    			&rtr2u2_at_buffer_last.gcs_update				},
/*18*/  { &rtr2u2_at_buffer_current.gcs_data_stream_send,   &rtr2u2_at_buffer_last.gcs_data_stream_send		},
/*19*/  { &rtr2u2_at_buffer_current.update_mount,    		&rtr2u2_at_buffer_last.update_mount				},
/*20*/  { &rtr2u2_at_buffer_current.update_events,    		&rtr2u2_at_buffer_last.update_events			},
/*21*/  { &rtr2u2_at_buffer_current.check_usb_mux,    		&rtr2u2_at_buffer_last.check_usb_mux			},
/*22*/  { &rtr2u2_at_buffer_current.read_battery,    		&rtr2u2_at_buffer_last.read_battery				},
/*23*/  { &rtr2u2_at_buffer_current.compass_accumulate,    	&rtr2u2_at_buffer_last.compass_accumulate		},
/*24*/  { &rtr2u2_at_buffer_current.barometer_accumulate,   &rtr2u2_at_buffer_last.barometer_accumulate		},
/*25*/  { &rtr2u2_at_buffer_current.update_notify,    		&rtr2u2_at_buffer_last.update_notify			},
/*26*/  { &rtr2u2_at_buffer_current.one_second_loop,    	&rtr2u2_at_buffer_last.one_second_loop			},
/*27*/  { &rtr2u2_at_buffer_current.check_long_failsafe,    &rtr2u2_at_buffer_last.check_long_failsafe		},
/*28*/  { &rtr2u2_at_buffer_current.airspeed_ratio_update,  &rtr2u2_at_buffer_last.airspeed_ratio_update	},
/*29*/  { &rtr2u2_at_buffer_current.update_logging,    		&rtr2u2_at_buffer_last.update_logging			},
/*30*/  { &rtr2u2_at_buffer_current.read_receiver_rssi,    	&rtr2u2_at_buffer_last.read_receiver_rssi		},
/*31*/ 	{ &rtr2u2_at_buffer_current.monitoring, 			&rtr2u2_at_buffer_last.monitoring			} //monitoring
};
#endif



#endif /* RTR2U2_LOW_LEVEL_OS */

enum rtr2u2_address_map_type {
    CURRENT_LOC,
    GPS,
    BATTERY,
    G,
    BAROMETER,
    HOME,
    NEXT_WP,
    COMPASS,
    INS_LAST_SAMPLE_TIME,	/* written in constructor of INS */
    LAST_HEARTBEAT,
    //SPI0_SEMAPHORE,
    CONTROL_MODE,
    INS_ACCEL_X,
    INS_ACCEL_Y,
    INS_ACCEL_Z,
    /* Dont edit last entry
     * Add new types above */
    ADDRESS_ENTRY_COUNT
};

/* Global Functions */
bool rtr2u2_update_signal(rtr2u2_signal_type signal, const void *pValue, const void *pValue2 );
void rtr2u2_register_static_address(rtr2u2_address_map_type type, const void *pAddress);
void monitoring();

#endif /* RTR2U2_EN */
#endif /* _AP_RTR2U2_H_ */
